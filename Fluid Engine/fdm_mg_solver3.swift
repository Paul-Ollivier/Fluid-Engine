//
//  fdm_mg_solver3.swift
//  vox.Force
//
//  Created by Feng Yang on 2020/8/28.
//  Copyright © 2020 Feng Yang. All rights reserved.
//

import Foundation

/// 3-D finite difference-type linear system solver using Multigrid.
class FdmMgSolver3: FdmLinearSystemSolver3 {
    var _mgParams = MgParameters<FdmBlas3>()
    var _sorFactor:Float
    var _useRedBlackOrdering:Bool
    
    /// Constructs the solver with given parameters.
    init(maxNumberOfLevels:size_t,
         numberOfRestrictionIter:UInt = 5,
         numberOfCorrectionIter:UInt = 5,
         numberOfCoarsestIter:UInt = 30,
         numberOfFinalIter:UInt = 30,
         maxTolerance:Float = 1e-9, sorFactor:Float = 1.5,
         useRedBlackOrdering:Bool = false) {
        self._mgParams.maxNumberOfLevels = maxNumberOfLevels
        self._mgParams.numberOfRestrictionIter = numberOfRestrictionIter
        self._mgParams.numberOfCorrectionIter = numberOfCorrectionIter
        self._mgParams.numberOfCoarsestIter = numberOfCoarsestIter
        self._mgParams.numberOfFinalIter = numberOfFinalIter
        self._mgParams.maxTolerance = maxTolerance
        if (useRedBlackOrdering) {
            _mgParams.relaxFunc = {(
                A:FdmMatrix3, b:FdmVector3,
                numberOfIterations:UInt, maxTolerance:Float, x:inout FdmVector3,
                buffer:inout FdmVector3) in
                
                for _ in 0..<numberOfIterations {
                    FdmGaussSeidelSolver3.relaxRedBlack(A: A, b: b, sorFactor: sorFactor, x: &x)
                }
            }
        } else {
            _mgParams.relaxFunc = {(
                A:FdmMatrix3, b:FdmVector3,
                numberOfIterations:UInt, maxTolerance:Float, x:inout FdmVector3,
                buffer:inout FdmVector3) in
                
                for _ in 0..<numberOfIterations {
                    FdmGaussSeidelSolver3.relax(A: A, b: b, sorFactor: sorFactor, x: &x)
                }
            }
        }
        _mgParams.restrictFunc = FdmMgUtils3.restrict
        _mgParams.correctFunc = FdmMgUtils3.correct
        
        self._sorFactor = sorFactor
        self._useRedBlackOrdering = useRedBlackOrdering
    }
    
    /// Returns the Multigrid parameters.
    func params()->MgParameters<FdmBlas3> {
        return _mgParams
    }
    
    /// Returns the SOR (Successive Over Relaxation) factor.
    func sorFactor()->Float {
        return _sorFactor
    }
    
    /// Returns true if red-black ordering is enabled.
    func useRedBlackOrdering()->Bool {
        return _useRedBlackOrdering
    }
    
    /// No-op. Multigrid-type solvers do not solve FdmLinearSystem3.
    func solve(system:inout FdmLinearSystem3)->Bool {
        return false
    }
    
    /// Solves Multigrid linear system.
    func solve(system:inout FdmMgLinearSystem3)->Bool {
        var buffer = FdmMgVector3()
        buffer.levels = Array<FdmVector3>(repeating: FdmVector3(), count: system.x.levels.count)
        for i in 0..<system.x.levels.count {
            buffer.levels[i] = FdmVector3(other: system.x.levels[i])
        }
        
        let result = mgVCycle(A: system.A, params: _mgParams,
                              x: &system.x, b: &system.b, buffer: &buffer)
        return result.lastResidualNorm < _mgParams.maxTolerance
    }
}

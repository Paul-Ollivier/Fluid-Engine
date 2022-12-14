//
//  point_particle_emitter2.swift
//  vox.Force
//
//  Created by Feng Yang on 2020/8/9.
//  Copyright © 2020 Feng Yang. All rights reserved.
//

import Foundation
import simd

/// 2-D point particle emitter.
///
/// This class emits particles from a single point in given direction, speed,
/// and spreading angle.
class PointParticleEmitter2: ParticleEmitter2 {
    var _isEnabled: Bool = true
    var _particles: ParticleSystemData2?
    var _onBeginUpdateCallback: OnBeginUpdateCallback?
    
    var _firstFrameTimeInSeconds:Double = 0.0
    var _numberOfEmittedParticles:size_t = 0
    
    var _maxNumberOfNewParticlesPerSecond:size_t
    var _maxNumberOfParticles:size_t
    
    var _origin:Vector2F
    var _direction:Vector2F
    var _speed:Float
    var _spreadAngleInRadians:Float
    
    
    /// Constructs an emitter that spawns particles from given origin,
    /// direction, speed, spread angle, max number of new particles per second,
    /// max total number of particles to be emitted, and random seed.
    /// - Parameters:
    ///   - origin: The origin.
    ///   - direction: The direction.
    ///   - speed: The speed.
    ///   - spreadAngleInDegrees:  The spread angle in degrees.
    ///   - maxNumOfNewParticlesPerSec: The max number of new particles per second.
    ///   - maxNumOfParticles: The max number of particles to be emitted.
    init(origin:Vector2F,
         direction:Vector2F,
         speed:Float,
         spreadAngleInDegrees:Float,
         maxNumOfNewParticlesPerSec:size_t = 1,
         maxNumOfParticles:size_t = size_t.max) {
        self._maxNumberOfNewParticlesPerSecond = maxNumOfNewParticlesPerSec
        self._maxNumberOfParticles = maxNumOfParticles
        self._origin = origin
        self._direction = direction
        self._speed = speed
        self._spreadAngleInRadians = Math.degreesToRadians(angleInDegrees: spreadAngleInDegrees)
    }
    
    /// Returns max number of new particles per second.
    func maxNumberOfNewParticlesPerSecond()->size_t {
        return _maxNumberOfNewParticlesPerSecond
    }
    
    /// Sets max number of new particles per second.
    func setMaxNumberOfNewParticlesPerSecond(rate:size_t) {
        _maxNumberOfNewParticlesPerSecond = rate
    }
    
    /// Returns max number of particles to be emitted.
    func maxNumberOfParticles()->size_t {
        return _maxNumberOfParticles
    }
    
    /// Sets max number of particles to be emitted.
    func setMaxNumberOfParticles(maxNumberOfParticles:size_t) {
        _maxNumberOfParticles = maxNumberOfParticles
    }
    
    /// Emits particles to the particle system data.
    /// - Parameters:
    ///   - currentTimeInSeconds: Current simulation time.
    ///   - timeIntervalInSeconds: The time-step interval.
    func onUpdate(currentTimeInSeconds:Double,
                  timeIntervalInSeconds:Double) {
        let particles = target()
        
        if (particles == nil) {
            return
        }
        
        if (_numberOfEmittedParticles == 0) {
            _firstFrameTimeInSeconds = currentTimeInSeconds
        }
        
        let elapsedTimeInSeconds = currentTimeInSeconds - _firstFrameTimeInSeconds
        
        var newMaxTotalNumberOfEmittedParticles:size_t
            = Int(ceil((elapsedTimeInSeconds + timeIntervalInSeconds) * Double(_maxNumberOfNewParticlesPerSecond)))
        newMaxTotalNumberOfEmittedParticles = min(newMaxTotalNumberOfEmittedParticles, _maxNumberOfParticles)
        let maxNumberOfNewParticles = newMaxTotalNumberOfEmittedParticles - _numberOfEmittedParticles
        
        if (maxNumberOfNewParticles > 0) {
            var candidatePositions = Array1<Vector2F>()
            var candidateVelocities = Array1<Vector2F>()
            
            emit(
                newPositions: &candidatePositions,
                newVelocities: &candidateVelocities,
                maxNewNumberOfParticles: maxNumberOfNewParticles)
            
            particles!.addParticles(newPositions: candidatePositions.constAccessor(),
                                    newVelocities: candidateVelocities.constAccessor())
            
            _numberOfEmittedParticles += candidatePositions.size()
        }
    }
    
    func emit(newPositions: inout Array1<Vector2F>,
              newVelocities: inout Array1<Vector2F>,
              maxNewNumberOfParticles:size_t) {
        var nP:[Vector2F] = []
        var nV:[Vector2F] = []
        for _ in 0..<maxNewNumberOfParticles {
            let newAngleInRadian = (random() - 0.5) * _spreadAngleInRadians
            let rotationMatrix = matrix_float2x2.makeRotationMatrix(rad: newAngleInRadian)
            
            nP.append(_origin)
            nV.append(_speed * (rotationMatrix * _direction))
        }
        
        newPositions.append(other: nP)
        newVelocities.append(other: nV)
    }
    
    func random()->Float {
        return Float.random(in: 0...1)
    }
    
    //MARK:- Builder
    /// Front-end to create PointParticleEmitter2 objects step by step.
    class Builder {
        var _maxNumberOfNewParticlesPerSecond:size_t = 1
        var _maxNumberOfParticles:size_t = size_t.max
        var _origin = Vector2F(0, 0)
        var _direction = Vector2F(0, 1)
        var _speed:Float = 1.0
        var _spreadAngleInDegrees:Float = 90.0
        
        /// Returns builder with origin.
        func withOrigin(origin:Vector2F)->Builder {
            _origin = origin
            return self
        }
        
        /// Returns builder with direction.
        func withDirection(direction:Vector2F)->Builder {
            _direction = direction
            return self
        }
        
        /// Returns builder with speed.
        func withSpeed(speed:Float)->Builder {
            _speed = speed
            return self
        }
        
        /// Returns builder with spread angle in degrees.
        func withSpreadAngleInDegrees(spreadAngleInDegrees:Float)->Builder {
            _spreadAngleInDegrees = spreadAngleInDegrees
            return self
        }
        
        func withMaxNumberOfNewParticlesPerSecond(
            maxNumOfNewParticlesPerSec:size_t)->Builder {
            _maxNumberOfNewParticlesPerSecond = maxNumOfNewParticlesPerSec
            return self
        }
        
        /// Returns builder with max number of particles.
        func withMaxNumberOfParticles(maxNumberOfParticles:size_t)->Builder {
            _maxNumberOfParticles = maxNumberOfParticles
            return self
        }
        
        /// Builds PointParticleEmitter2.
        func build()->PointParticleEmitter2 {
            return PointParticleEmitter2(
                origin: _origin,
                direction: _direction,
                speed: _speed,
                spreadAngleInDegrees: _spreadAngleInDegrees,
                maxNumOfNewParticlesPerSec: _maxNumberOfNewParticlesPerSecond,
                maxNumOfParticles: _maxNumberOfParticles)
        }
    }
    
    /// Returns builder fox PointParticleEmitter2.
    static func builder()->Builder{
        return Builder()
    }
}

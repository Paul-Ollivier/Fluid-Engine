//
//  grid_system_data2.swift
//  vox.Force
//
//  Created by Feng Yang on 2020/8/6.
//  Copyright © 2020 Feng Yang. All rights reserved.
//

import Foundation

/// 2-D grid system data.
///
/// This class is the key data structure for storing grid system data. To
/// represent a grid system for fluid simulation, velocity field is defined as a
/// face-centered (MAC) grid by default. It can also have additional scalar or
/// vector attributes by adding extra data layer.
class GridSystemData2 {
    var _resolution:Size2 = Size2()
    var _gridSpacing:Vector2F = Vector2F()
    var _origin:Vector2F = Vector2F()
    
    var _velocity:FaceCenteredGrid2?
    var _velocityIdx:size_t = 0
    var _scalarDataList:[ScalarGrid2] = []
    var _vectorDataList:[VectorGrid2] = []
    var _advectableScalarDataList:[ScalarGrid2] = []
    var _advectableVectorDataList:[VectorGrid2] = []
    
    /// Constructs empty grid system.
    convenience init() {
        self.init(resolution: Size2(),
                  gridSpacing: Vector2F(1,1),
                  origin: Vector2F())
    }
    
    /// Constructs a grid system with given resolution, grid spacing and origin.
    ///
    /// This constructor builds the entire grid layers within the system. Note,
    /// the resolution is the grid resolution, not the data size of each grid.
    /// Depending on the layout of the grid, the data point may lie on different
    /// part of the grid (vertex, cell-center, or face-center), thus can have
    /// different array size internally. The resolution of the grid means the
    /// grid cell resolution.
    /// - Parameters:
    ///   - resolution: The resolution.
    ///   - gridSpacing: The grid spacing.
    ///   - origin:  The origin.
    init(resolution:Size2,
         gridSpacing:Vector2F,
         origin:Vector2F) {
        self._velocity = FaceCenteredGrid2()
        self._advectableVectorDataList.append(self._velocity!)
        self._velocityIdx = 0
        resize(resolution: resolution, gridSpacing: gridSpacing, origin: origin)
    }
    
    /// Copy constructor.
    init(other:GridSystemData2) {
        resize(resolution: other._resolution,
               gridSpacing: other._gridSpacing,
               origin: other._origin)
        
        for data in other._scalarDataList{
            _scalarDataList.append(data.clone())
        }
        for data in other._vectorDataList{
            _vectorDataList.append(data.clone())
        }
        for data in other._advectableScalarDataList{
            _advectableScalarDataList.append(data.clone())
        }
        for data in other._advectableVectorDataList{
            _advectableVectorDataList.append(data.clone())
        }
        
        VOX_ASSERT(self._advectableVectorDataList.count > 0)
        self._velocity = _advectableVectorDataList[0] as? FaceCenteredGrid2
        VOX_ASSERT(_velocity != nil)
        self._velocityIdx = 0
    }
    
    /// Resizes the whole system with given resolution, grid
    ///     spacing, and origin.
    ///
    /// This function resizes the entire grid layers within the system. Note,
    /// the resolution is the grid resolution, not the data size of each grid.
    /// Depending on the layout of the grid, the data point may lie on different
    /// part of the grid (vertex, cell-center, or face-center), thus can have
    /// different array size internally. The resolution of the grid means the
    /// grid cell resolution.
    /// - Parameters:
    ///   - resolution:  The resolution.
    ///   - gridSpacing: The grid spacing.
    ///   - origin: The origin.
    func resize(resolution:Size2,
                gridSpacing:Vector2F,
                origin:Vector2F) {
        _resolution = resolution
        _gridSpacing = gridSpacing
        _origin = origin
        
        for data in _scalarDataList {
            data.resize(resolution: resolution,
                        gridSpacing: gridSpacing,
                        origin: origin)
        }
        for data in _vectorDataList {
            data.resize(resolution: resolution,
                        gridSpacing: gridSpacing,
                        origin: origin)
        }
        for data in _advectableScalarDataList {
            data.resize(resolution: resolution,
                        gridSpacing: gridSpacing,
                        origin: origin)
        }
        for data in _advectableVectorDataList {
            data.resize(resolution: resolution,
                        gridSpacing: gridSpacing,
                        origin: origin)
        }
    }
    
    /// Returns the resolution of the grid.
    ///
    /// This function resizes the entire grid layers within the system. Note,
    /// the resolution is the grid resolution, not the data size of each grid.
    /// Depending on the layout of the grid, the data point may lie on different
    /// part of the grid (vertex, cell-center, or face-center), thus can have
    /// different array size internally. The resolution of the grid means the
    /// grid cell resolution.
    /// - Returns: Grid cell resolution.
    func resolution()->Size2 {
        return _resolution
    }
    
    /// Return the grid spacing.
    func gridSpacing()->Vector2F {
        return _gridSpacing
    }
    
    /// Returns the origin of the grid.
    func origin()->Vector2F {
        return _origin
    }
    
    /// Returns the bounding box of the grid.
    func boundingBox()->BoundingBox2F {
        return _velocity!.boundingBox()
    }
    
    /// Adds a non-advectable scalar data grid by passing its
    ///     builder and initial value.
    ///
    /// This function adds a new scalar data grid. This layer is not advectable,
    /// meaning that during the computation of fluid flow, this layer won't
    /// follow the flow. For the future access of this layer, its index is
    /// returned.
    /// - Parameters:
    ///   - builder: The grid builder.
    ///   - initialVal: The initial value.
    /// - Returns: Index of the data.
    func addScalarData(builder:ScalarGridBuilder2,
                       initialVal:Float = 0.0)->size_t {
        let attrIdx = _scalarDataList.count
        _scalarDataList.append(
            builder.build(resolution: resolution(),
                          gridSpacing: gridSpacing(),
                          gridOrigin: origin(),
                          initialVal: initialVal))
        return attrIdx
    }
    
    /// Adds a non-advectable vector data grid by passing its
    ///     builder and initial value.
    ///
    /// This function adds a new vector data grid. This layer is not advectable,
    /// meaning that during the computation of fluid flow, this layer won't
    /// follow the flow. For the future access of this layer, its index is
    /// returned.
    /// - Parameters:
    ///   - builder: The grid builder.
    ///   - initialVal: The initial value.
    /// - Returns: Index of the data.
    func addVectorData(builder:VectorGridBuilder2,
                       initialVal:Vector2F = Vector2F())->size_t {
        let attrIdx = _vectorDataList.count
        _vectorDataList.append(
            builder.build(resolution: resolution(),
                          gridSpacing: gridSpacing(),
                          gridOrigin: origin(),
                          initialVal: initialVal))
        return attrIdx
    }
    
    /// Adds an advectable scalar data grid by passing its builder
    ///     and initial value.
    ///
    /// This function adds a new scalar data grid. This layer is advectable,
    /// meaning that during the computation of fluid flow, this layer will
    /// follow the flow. For the future access of this layer, its index is
    /// returned.
    /// - Parameters:
    ///   - builder: The grid builder.
    ///   - initialVal: The initial value.
    /// - Returns: Index of the data.
    func addAdvectableScalarData(
        builder:ScalarGridBuilder2,
        initialVal:Float = 0.0)->size_t {
        let attrIdx = _advectableScalarDataList.count
        _advectableScalarDataList.append(
            builder.build(resolution: resolution(),
                          gridSpacing: gridSpacing(),
                          gridOrigin: origin(),
                          initialVal: initialVal))
        return attrIdx
    }
    
    /// Adds an advectable vector data grid by passing its builder
    ///     and initial value.
    ///
    /// This function adds a new vector data grid. This layer is advectable,
    /// meaning that during the computation of fluid flow, this layer will
    /// follow the flow. For the future access of this layer, its index is
    /// returned.
    /// - Parameters:
    ///   - builder: The grid builder.
    ///   - initialVal: The initial value.
    /// - Returns: Index of the data.
    func addAdvectableVectorData(
        builder:VectorGridBuilder2,
        initialVal:Vector2F = Vector2F())->size_t {
        let attrIdx = _advectableVectorDataList.count
        _advectableVectorDataList.append(
            builder.build(resolution: resolution(),
                          gridSpacing: gridSpacing(),
                          gridOrigin: origin(),
                          initialVal: initialVal))
        return attrIdx
    }
    
    /// Returns the velocity field.
    ///
    /// This class has velocify field by default, and it is part of the
    /// advectable vector data list.
    /// - Returns: Pointer to the velocity field.
    func velocity()->FaceCenteredGrid2 {
        return _velocity!
    }
    
    /// Returns the index of the velocity field.
    ///
    /// This class has velocify field by default, and it is part of the
    /// advectable vector data list. This function returns the index of the
    /// velocity field from the list.
    /// - Returns: Index of the velocity field.
    func velocityIndex()->size_t {
        return _velocityIdx
    }
    
    /// Returns the non-advectable scalar data at given index.
    func scalarDataAt(idx:size_t)->ScalarGrid2 {
        return _scalarDataList[idx]
    }
    
    /// Returns the non-advectable vector data at given index.
    func vectorDataAt(idx:size_t)->VectorGrid2 {
        return _vectorDataList[idx]
    }
    
    /// Returns the advectable scalar data at given index.
    func advectableScalarDataAt(idx:size_t)->ScalarGrid2 {
        return _advectableScalarDataList[idx]
    }
    
    /// Returns the advectable vector data at given index.
    func advectableVectorDataAt(idx:size_t)->VectorGrid2 {
        return _advectableVectorDataList[idx]
    }
    
    /// Returns the number of non-advectable scalar data.
    func numberOfScalarData()->size_t {
        return _scalarDataList.count
    }
    
    /// Returns the number of non-advectable vector data.
    func numberOfVectorData()->size_t {
        return _vectorDataList.count
    }
    
    /// Returns the number of advectable scalar data.
    func numberOfAdvectableScalarData()->size_t {
        return _advectableScalarDataList.count
    }
    
    /// Returns the number of advectable vector data.
    func numberOfAdvectableVectorData()->size_t {
        return _advectableVectorDataList.count
    }
}

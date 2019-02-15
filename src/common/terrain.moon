
utils = require("utils")

import OdfFile from utils

HEIGHT_TOLERANCE = 5
NORMAL_TOLERANCE = 0.1

class Terrain
  new: (filename) =>
    @file = OdfFile(filename)
    
    @minVec = SetVector(@file\getInt("Size", "MinX"), @file\getInt("Size", "Height"), @file\getInt("Size", "MinZ"))
    @maxVec = @minVec + SetVector(@file\getInt("Size", "Width"), 0, @file\getInt("Size", "Depth"))


  getSize: () =>
    @maxVec - @minVec

  getBoundary: () =>
    return @minVec, @maxVec



return {
  :Terrain
}
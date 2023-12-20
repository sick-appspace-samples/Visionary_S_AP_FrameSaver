--[[----------------------------------------------------------------------------

  Application Name: Visionary_S_AP_FrameSaver

  Summary:
  Save a frame of image to the public directory of the device

  Description:
  Set up the camera to take live images continuously. React to the "Submit" event
  from the "Save to device" button to store the image in the public directory of
  the device (Click "Refresh AppData" to see resulting images in the AppData tab).

  How to run:
  Start by running the app (F5) or debugging (F7+F10).
  Set a breakpoint on the first row inside the main function to debug step-by-step.
  See the results in the different image viewer on the DevicePage.

  More Information:
  If you want to run this app on an emulator some changes are needed to get images.
  The statemap should be used as an error map for overlaying.

------------------------------------------------------------------------------]]
--Start of Global Scope---------------------------------------------------------
-- Variables, constants, serves etc. should be declared here.

--setup the camera, set default config and get the camera model
local camera = Image.Provider.Camera.create()
Image.Provider.Camera.stop(camera)
local config = Image.Provider.Camera.getDefaultConfig(camera)
Image.Provider.Camera.setConfig(camera, config)
local cameraModel = Image.Provider.Camera.getInitialCameraModel(camera)

--setup the  views
local viewer2D = View.create("viewer2D")

local decoLocalZ = View.ImageDecoration.create()
decoLocalZ:setRange(0, 6500)

local decoStatemap = View.ImageDecoration.create()
decoStatemap:setRange(0, 100)

--object to store the image
local zMapImage = Image.create(640, 512, "UINT16")
local stateMapImage = Image.create(640, 512, "UINT16")
local colorImage = Image.create(640, 512, "RGB24")

--directory to save the image
local filePath = "/public/"

---@return string
---@return string
---@return string
local function generateFileNames()
  local day, month, year, hour, minute, second = DateTime.getDateTimeValuesLocal()
  local timestamp = year .. month .. day .. "_" .. hour .. minute .. second .. "_"

  return timestamp .. "ZMap", timestamp .. "StateMap", timestamp .. "Color"
end

local function saveImage()
  --generate the file names with timestamp
  local zMapImgFileName, stateMapImgFileName, colorImgFileName = generateFileNames()

  -- --Save the captured image to the specified directory
  Image.save(zMapImage, filePath .. zMapImgFileName .. ".png")
  Image.save(stateMapImage, filePath .. stateMapImgFileName .. ".png")
  Image.save(colorImage, filePath .. colorImgFileName .. ".png")
end
Script.serveFunction("Visionary_S_AP_FrameSaver.saveImage", saveImage)

local function deleteImages()
  --List all png files in the directory
  local fileList = File.list(filePath, "*.png")

  --Delete all existing png files in the directory
  for i,v in ipairs(fileList) do
    File.del(filePath .. v)
  end
end
Script.serveFunction("Visionary_S_AP_FrameSaver.deleteImages", deleteImages)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------
local function main()
  Image.Provider.Camera.start(camera)
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register("Engine.OnStarted", main)

---@param image Image
---@param sensordata SensorData
local function handleOnNewImage(images)
  View.addDepthmap(viewer2D, images, cameraModel, {decoLocalZ, decoStatemap}, {"Local Z", "Statemap", "Color"})

  --Show in the viewer using present
  View.present(viewer2D)

  --retain copies of the images
  zMapImage = images[1]
  stateMapImage = images[2]
  colorImage = images[3]
end

eventQueueHandle = Script.Queue.create()
eventQueueHandle:setMaxQueueSize(1)
eventQueueHandle:setPriority("HIGH")
eventQueueHandle:setFunction(handleOnNewImage)
Image.Provider.Camera.register(camera, "OnNewImage", handleOnNewImage)

--End of Function and Event Scope-----------------------------------------------
local guiRig
local sceneLink
local active

local function name()
  -- Return the name of the plugin.
  return "Annotation Dictate"
end

local function version()
  -- Return the version number of the plugin.
  return "0.0.1"
end

local function init()
  -- Create a little floating button that we can position somewhere close to the selected annotation
  guiRig = vrCreateNode("Assembly", "AnnotationDictationControls", vrLocalUserNode())
  guiRig.Enabled = false
  
  local bill = vrCreateNode("Billboard", "Billboard", guiRig)
  bill.SizeMode = __Billboard_SizeModeView
  bill.ViewScale = 0.1
  bill.WorldPosition.Y = 0.05
  
  local gui = vrCreateNode("GUI", "GUI", bill)
  gui.DepthTest = false
  
  local button = vrCreateNode("Button", "Button", gui)
  button.Toggle = true
  button.Text = "D"
  
	-- Since we created the GUI in the user tree we need to add a SceneLink in order for it to be rendered
  sceneLink = vrCreateNode("SceneLink", "AnnotationDictationControls", vrLocalUserNode().UserScene)
  sceneLink.RootNode = guiRig
  sceneLink.Owner = vrLocalUserNode()
  sceneLink.VisibleToOwner = true
  sceneLink.VisibleToOthers = false
  
	-- Utility function for moving our GUI rig near the specified annotation
  local function updateControls(node)
    active = node
    if not node or not node.TargetAssembly then
      guiRig.Enabled = false
    else
      guiRig.Enabled = true
      guiRig.Transform.Position = node.TargetAssembly.WorldTransform.Position + node.Position
    end
  end
  
	-- Add an observer to watch for changes to the active annotation,
	-- e.g. when a new one is created, or the user uses the Review tools to seek to an annotation
  vrAddPropertyObserver("AnnotationListObserver", function(node, value)
    updateControls(value)
    vrAddNodeObserver("activeAnnotationObserver", value, {
      valuesChanged = function(node)
        updateControls(node) -- move our button to this annotation
      end
    })
  end, "AnnotationList", "ActiveAnnotation")
  
	-- Register the speech callback and when we receive text from it, 
	-- create a comment on the active annotation
  __registerCallback("onSpeech", function(text) 
    if button.Toggled and active then 
      local c = vrAnnotationCreateComment(active)
      vrAnnotationSetCommentText(c, text)
    end 
  end)
  
	-- Observe the toggle state of our gui button to control the state of the speech to text listener
  vrAddNodeObserver("RecordingToggle", button, {
    valuesChanged = function(node)
      if node.Toggled == true then
        AzureSpeechToText.StartListening()
      else
        AzureSpeechToText.StopListening()
      end
    end 
  })
end

local function cleanup()
  vrRemoveObserver("RecordingToggle")
  vrRemoveObserver("AnnotationListObserver")
  vrRemoveObserver("activeAnnotationObserver")
  
  if guiRig then
    vrDeleteNode(guiRig)
  end
  
  if sceneLink then
    vrDeleteNode(sceneLink)
  end
    
end

local function depends()
  return "AzureSpeechToText"
end

-- Export the plugin functions to the Lua state.
return {
  name = name,
  version = version,
  init = init,
  cleanup = cleanup,
  depends = depends
}
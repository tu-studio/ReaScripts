start_track = 5
end_track = start_track+31

-- param order is not the same between the plugins
-- param old new
-- x_pos  0   4
-- y_pos  1   5
-- z_pos  2   6
-- wfs    3   1
-- hoa    4   0
-- rev    5   2
param_idx_new = {4,5,6,1,0,2}

new_plugin_name = "Seamless Client"
old_plugin_name = "Seamless_Client"
scaling_factor = 12.108

-- if rotate x_rot=-y_old, y_rot=x_old
rotate = true

-- swap x and y target idx if rotate == true, actual rotation happens later
-- rotation is done by first swapping the indices and later inverting the x-axis
if rotate then
  x_new_idx = param_idx_new[1]
  y_new_idx = param_idx_new[2]

  param_idx_new[1] = y_new_idx
  param_idx_new[2] = x_new_idx
end

function FlattenAutomationItems(env)
  -- handle automation items (by removing them)
  local n_automation_items = reaper.CountAutomationItems(env)
  if n_automation_items > 0 then
    local delete_automation_item_command_id = 42088

    -- make envelope visible, otherwise calling the deletion command does not work
    local r, s = reaper.GetSetEnvelopeInfo_String(env, "VISIBLE", "1", true)
    
    for autoitem_index = 0, n_automation_items - 1 do
      reaper.GetSetAutomationItemInfo(env, autoitem_index, "D_UISEL", 1, true)
    end
    reaper.Main_OnCommand(delete_automation_item_command_id, 0)
    reaper.UpdateTimeline()

    n_automation_items = reaper.CountAutomationItems(env)
    if n_automation_items > 0 then
      reaper.ShowConsoleMsg("ERROR: could not remove automation items for track "..reaper.GetEnvelopeName(env)..  ": "..n_automation_items.." Items remaining\n")
    end
  end
end

-- track_idx is the index of the envelope of the plugin
function CopyAndTransformEnvelope(src_env, target_env, track_idx)
  local n_env_points_old = reaper.CountEnvelopePointsEx(src_env, -1)

  for point_idx = 0, n_env_points_old - 1 do
    -- get old envelope point
    local _, time, value, shape, tension, _ = reaper.GetEnvelopePointEx(src_env,-1, point_idx)
    
    -- transform coordinate
    if track_idx <= 2 then
      -- scale (0,1) normalized value to (-10,10)
      value = (value * 20) - 10

      
      value = value / scaling_factor
      -- flip y coordinate if rotating
      if rotate and track_idx == 1 then
        value = value * -1
      end
      -- scale back from (-1,1) to (0,1)
      value = (value + 1)/2

    end

    -- write point to new envelope
    reaper.InsertEnvelopePointEx(target_env, -1, time, value, shape, tension, true, true)
  end

  -- sort points for some reason
  reaper.Envelope_SortPointsEx(target_env, -1)


  -- did it work? lets find out
  local n_env_points_new = reaper.CountEnvelopePoints(target_env)
  if n_env_points_new ~= n_env_points_old then
    reaper.ShowConsoleMsg("ERROR:  " .. reaper.GetEnvelopeName(src_env) .. " n_items_old:"..n_env_points_old.. " n_items_new:"..n_env_points_new.. "\n")
  end
end



-- get project length (in s)
current_project, _ = reaper.EnumProjects(-1)
project_length = reaper.GetProjectLength(current_project)

-- iterate over all relevant track indices
for track_idx = start_track,end_track do
  local track = reaper.GetTrack(0, track_idx)
  
  local _, track_name = reaper.GetTrackName(track)
  reaper.ShowConsoleMsg("\ntrack: "..track_name.."\n")
  
  -- add new seamless plugin if not already present
  local new_plugin_idx = reaper.TrackFX_AddByName(track, new_plugin_name, false, 1)
  local old_plugin_idx = reaper.TrackFX_AddByName(track, old_plugin_name, false, 0)

  -- migrate gain parameters
  for i = 0, 5 do
    local old_env = reaper.GetFXEnvelope(track, old_plugin_idx, i, false)


    local new_i = param_idx_new[i+1]
    local new_env = reaper.GetFXEnvelope(track, new_plugin_idx,new_i , true)
    -- clear envelope points on the new envelope
    reaper.DeleteEnvelopePointRange(new_env, 0, project_length)


    local _, param_name_new = reaper.GetEnvelopeName(new_env)
    
    if old_env ~= nil then      
      -- this is where most of the magic happens
      FlattenAutomationItems(old_env)
      CopyAndTransformEnvelope(old_env, new_env, i)
      
    else
      reaper.ShowConsoleMsg("skipped envelope for ".. param_name_new .. " with index " .. i .."\n")
    end
  end
  
end

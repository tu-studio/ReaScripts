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

for i = start_track,end_track do
  track = reaper.GetTrack(0, i)
  
  _, track_name = reaper.GetTrackName(track)
  print("track: "..track_name)
  
  -- add new seamless plugin if not already present
  new_plugin_idx = reaper.TrackFX_AddByName(track, new_plugin_name, false, 1)
  old_plugin_idx = reaper.TrackFX_AddByName(track, old_plugin_name, false, 0)
  count = 0
  for i = 0, 5 do
    old_env = reaper.GetFXEnvelope(track, old_plugin_idx, i, false)
    new_i = param_idx_new[i+1]
    new_env = reaper.GetFXEnvelope(track, new_plugin_idx,new_i , true)
    if old_env ~= nil then 
      
    
      _, param_name_old = reaper.GetEnvelopeName(old_env)
      _, param_name_new = reaper.GetEnvelopeName(new_env)
      n_env_points_old = reaper.CountEnvelopePointsEx(old_env, -1)
      n_env_points_new = reaper.CountEnvelopePointsEx(new_env, -1)
      
      for point_idx = 0, n_env_points_old - 1 do
        retval, time, value, shape, tension, selected = reaper.GetEnvelopePointEx(old_env,-1, point_idx)
        reaper.InsertEnvelopePointEx(new_env, -1, time, value, shape, tension, true, true)
      end
      reaper.Envelope_SortPointsEx(new_env, -1)
      n_env_points_new = reaper.CountEnvelopePoints(new_env)
      print("  " .. param_name_old .. " n_items:"..n_env_points_old.."\n")
      print("  " .. param_name_new .. " n_items:"..n_env_points_new.."\n")    
    else
      print("skipped something")
    end
  end
  
  
end

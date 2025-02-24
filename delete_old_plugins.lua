start_track = 5
end_track = start_track+31

old_plugin_name = "Seamless_Client"


for i = start_track,end_track do
  track = reaper.GetTrack(0, i)
  
  _, track_name = reaper.GetTrackName(track)
  reaper.ShowConsoleMsg("\ntrack: "..track_name.."\n")
  
  -- get seamless plugin
  old_plugin_idx = reaper.TrackFX_AddByName(track, old_plugin_name, false, 0)

  reaper.TrackFX_Delete(track, old_plugin_idx)
  
end

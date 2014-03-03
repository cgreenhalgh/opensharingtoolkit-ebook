# coffee script for ebook (experiment)
# module.exports = ...?

appCache = window.applicationCache

onCacheUpdate = () ->
  status = switch appCache.status
    when appCache.UNCACHED then 'uncached'
    when appCache.IDLE then 'idle'
    when appCache.CHECKING then 'checking'
    when appCache.DOWNLOADING then 'downloading'
    when appCache.UPDATEREADY then 'updateready'
    when appCache.OBSOLETE then 'obsolete'
    else 'unknown ('+appCache.status+')'
  console.log 'AppCache status = '+status
  $('#cacheFeedback').html 'Cache '+status
  if appCache.status == appCache.UPDATEREADY
    $(":mobile-pagecontainer").pagecontainer "change", "#updateready", {changeHash:true,reload:true}


module.exports.init = () ->
  if not appCache?
    console.log 'no appCache'
    $('#cacheFeedback').html 'Sorry, cannot cache on this device'
    return false
  onCacheUpdate()
  $(appCache).bind "cached checking downloading error noupdate obsolete progress updateready", (ev) ->
    console.log 'appCache event '+ev.type+', status = '+appCache.status
    onCacheUpdate()
    false
  #$(window).on 'navigate',(ev,data)->
  #  console.log 'navigate'
  #$('#reload').on 'click', (ev)->
  #  #ev.preventDefault()
  #  console.log 'defer reload'
  #  setTimeout 10,()->
  #    console.log 'reload'
  #    window.location.reload()
  #  return true

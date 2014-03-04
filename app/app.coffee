# coffee script for ebook (experiment)
# module.exports = ...?

appCache = window.applicationCache

onCacheUpdate = () ->
  bookmark = true
  status = switch appCache.status
    when appCache.UNCACHED  
      bookmark = false
      'This eBook is not saved; you will need Internet access to view it again'
    when appCache.IDLE, appCache.UPDATEREADY 
      'Saved for off-Internet use'
    when appCache.CHECKING, appCache.DOWNLOADING 
      'Checking for a new version'
    when appCache.OBSOLETE 
      'obsolete'
    else 
      'There unknown ('+appCache.status+')'
  console.log 'AppCache status = '+status
  if bookmark
    status = status+"<br/>Bookmark this page to view it later"
  $('#cacheFeedback').html status

module.exports.init = () ->
  if not appCache?
    console.log 'no appCache'
    #$('#cacheFeedback').html 'This eBook is not saved; you will need Internet access to view it again'
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

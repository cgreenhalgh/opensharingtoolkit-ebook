# coffee script for ebook (experiment)
# module.exports = ...?

appCache = window.applicationCache

onCacheUpdate = () ->
  bookmark = true
  status = switch appCache.status
    when appCache.UNCACHED  
      bookmark = false
      'This eBook is not saved; you will need Internet access to view it again'
    when appCache.IDLE
      'Saved for off-Internet use'
    when appCache.UPDATEREADY 
      '<a href="#reload">Reload the new version</a>'
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

delayedLink = null
pageStack = []

$( document ).on "mobileinit", ()->
  console.log 'mobileinit'
  $.mobile.pushStateEnabled = false
  $.mobile.ajaxEnabled = false
  $.mobile.linkBindingEnabled = false

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
  #$.mobile.linkBindingEnabled = false
  console.log "mobile config anyway..."
  $.mobile.pushStateEnabled = false
  $.mobile.ajaxEnabled = false
  $.mobile.linkBindingEnabled = false
  $(document).on 'click','a',(ev)->
    href = $(ev.currentTarget).attr 'href'
    # scheme?
    if href.indexOf(':') >= 0 or href.indexOf('//') == 0
      console.log "Delayed click #{href}"
      activePage = $("body").pagecontainer 'getActivePage'
      activeId = activePage.get(0).id
      pageStack.push activeId
      delayedLink = href
      $('#linkUrl').text href
      #location.hash = 'link'
      $("body").pagecontainer 'change','#link',{changeHash:false}
      false
    else if $(ev.currentTarget).parents('div[id=link]').length>0
      console.log "click on link page #{href}"
      if pageStack.length>0
        backUrl = '#'+pageStack[pageStack.length-1]
      else
        console.log "pageStack empty!"
        backUrl = '#'
      $("body").pagecontainer 'change',backUrl,{changeHash:false}
      false
    else if href=='#reload'
      console.log 'Reload...'
      event.preventDefault()
      try
        window.applicationCache.swapCache()
      catch err
        console.log "error swapping cache: #{err}"
      window.location.reload()
    else
      console.log "click #{href}"
      true
  $('#linkOpen').on 'click',(ev)->
    # delayed open
    open = () -> 
      if delayedLink
        window.open delayedLink 
    setTimeout open,100
    true


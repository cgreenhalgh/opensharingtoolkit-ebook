# coffee-script epub2html convertor.
# Converts epub file (initial development/testing with booktype 1.6.1) to a HTML5 offline mini-site.

eco = require "eco"
fs = require 'fs'
unzip = require 'unzip'
xml2js = require 'xml2js'

console.log 'reading templates...'
htmlTemplate = fs.readFileSync __dirname + "/templates/html.eco", "utf-8"
coverTemplate = fs.readFileSync __dirname + "/templates/cover.eco", "utf-8"
landingTemplate = fs.readFileSync __dirname + "/templates/landing.eco", "utf-8"
aboutTemplate = fs.readFileSync __dirname + "/templates/about.eco", "utf-8"
tocTemplate = fs.readFileSync __dirname + "/templates/toc.eco", "utf-8"
bodyTemplate = fs.readFileSync __dirname + "/templates/body.eco", "utf-8"
navTemplate = fs.readFileSync __dirname + "/templates/nav.eco", "utf-8"

if process.argv.length<4
  console.log 'usage: coffee epub2html.coffee <EPUBFILE> <OUTDIRNAME>'
  process.exit -1

epubfn = process.argv[2]
outdn = process.argv[3]

mkpdirs = (path) ->
  ix = path.lastIndexOf '/'
  if ix>=0
    dir = path.substring 0,ix
    if dir.length > 0
      mkpdirs dir 
      if not fs.existsSync dir
        console.log "Create directory #{dir}"
        fs.mkdirSync dir

mkpdirs outdn
if fs.existsSync outdn
  outstat = fs.statSync outdn
  if not outstat.isDirectory()
    console.log "Error: output exists and is not a directory: #{outdn}"
    process.exit -1
  console.log "Warning: output directory exists: #{outdn}"
  
else
  console.log "Create output directory #{outdn}"
  fs.mkdirSync outdn

# TODO
EPUBDIR = "/epub/"

console.log "Read epub file #{epubfn}..."
parse = fs.createReadStream(epubfn).pipe(unzip.Parse())
parse.on 'entry', (entry) ->
    fileName = entry.path
    type = entry.type # 'Directory' or 'File'
    console.log "Found entry #{type} #{fileName}" 
    if (type == "File")
      path = outdn+EPUBDIR+fileName
      mkpdirs path
      entry.pipe(fs.createWriteStream(path))
    else 
      entry.autodrain();

flatten = (array) ->
  flattened = []
  for element in array
    if element instanceof Array
      flattened = flattened.concat flatten element
    else
      flattened.push element
  flattened

EPUB_OPF_MIMETYPE = "application/oebps-package+xml"

findItem = (manifest,id) ->
  items = for item in manifest.item when item.$.id is id
    item
  if items.length >= 0
    return items[0]
  throw "could not find item #{id} in manifest #{JSON.stringify manifest}"


checkContainer = () ->
  confn = outdn+EPUBDIR+"META-INF/container.xml"
  console.log "Try to read epub container info #{confn}..."
  scon = fs.readFileSync confn, 'utf8'
  parser = new xml2js.Parser()
  parser.parseString scon,(err,result) ->
    if err 
      console.log "Error parsing #{confn}: #{err}"
      process.exit -1
    #console.log "Found #{JSON.stringify result.container}"
    roots = for rootfiles in result.container?.rootfiles?= [] 
      for rootfile in rootfiles.rootfile ?= []
        rootfile
    for root in flatten roots
      mediatype = root.$['media-type']
      rootfn = root.$['full-path']
      if mediatype != EPUB_OPF_MIMETYPE
        console.log "Error: unsupport epub package #{rootfn} of type #{mediatype}"
        
      #console.log "Found epub package #{rootfn}"
      packfn = outdn+EPUBDIR+rootfn
      console.log "Try to read epub package #{packfn}"
      spack = fs.readFileSync packfn, 'utf8'
      pparser = new xml2js.Parser()
      pparser.parseString spack,(err,result) ->
        if err 
          console.log "Error parsing #{packfn}: #{err}"
          process.exit -1
        version = result.package?.$?.version
        if version != "2.0"
          console.log "Warning: this application was written for version 2.0 / booktype 1.6.1 (found epub version #{version})"
        console.log "Read package version #{version}"
        if result.package?.metadata?.length != 1
          console.log "Badly formatted package; found #{result.package?.metadata?.length} metadata elements"
          process.exit -1
        metadata = result.package.metadata[0]
        if result.package?.manifest?.length != 1
          console.log "Badly formatted package; found #{result.package?.manifest?.length} manifest elements"
          process.exit -1
        manifest = result.package.manifest[0]
        if result.package?.spine?.length != 1
          console.log "Badly formatted package; found #{result.package?.spine?.length} spine elements"
          process.exit -1
        spine = result.package.spine[0]

        # ncx file - superceded in version 3
        if spine.$.toc?
          tocfn = outdn+EPUBDIR+(findItem manifest,spine.$.toc).$.href
          console.log "Try to read TOC #{tocfn}..."
          stoc = fs.readFileSync tocfn,'utf8'
          
          tparser = new xml2js.Parser()
          tparser.parseString stoc,(err,result) ->
            if err 
              console.log "Error parsing TOC #{tocfn}: #{err}"
              process.exit -1
            if result.ncx?.navMap?.length != 1
              console.log "Badly formatted TOC (ncx); found #{result.ncx?.navMap?.length} navMap elements"
              process.exit -1
            navMap = result.ncx.navMap[0]
            processEpub result.package,metadata,manifest,spine,navMap

        else
          console.log "Warning: no TOC found"
          processEpub result.package,metadata,manifest,spine,undefined

parse.on 'close', () ->
    console.log "Closed" 
    checkContainer()

# go async...

allMeta = (metadata,name) ->
  if metadata[name]? and metadata[name].length>0 and metadata[name][0]._?
    # complex element
    for el in metadata[name]
      el._
  else if metadata[name]? and metadata[name].length>0
    # simple element
    metadata[name]
  else
    []

firstMeta = (metadata,name) ->
  if metadata[name]? and metadata[name].length>0 and metadata[name][0]._?
    # complex element
    metadata[name][0]._
  else if metadata[name]? and metadata[name].length>0
    # simple element
    metadata[name][0]
  else
    console.log "Could not find metadata #{name} in #{JSON.stringify metadata}"
    undefined

findCoverImages = (manifest) ->
  for item in manifest.item when (item.$.properties?.indexOf 'cover-image') >= 0
    item.$.href

findFiles = (html, attribute) ->
  files = []
  ix = 0
  while ix>=0
    ix = html.indexOf " #{attribute}=\"",ix
    #console.log "- start of #{attribute} at #{ix}"
    if ix>=0
      ix2 = html.indexOf '"',ix+3+attribute.length
      #console.log "- end of #{attribute} at #{ix2}"
      if ix2>=0
        #console.log "- added #{html.substring ix+3+attribute.length,ix2}"
        files.push (html.substring ix+3+attribute.length,ix2)
      ix = ix2
  files

makeNavbar = (previd,pageid,nextid) ->
  try
    #console.log "makeNavbar previd=#{previd}"
    return eco.render navTemplate, {previd: previd, pageid: pageid, nextid: nextid}
  catch err
    console.log "Error templating navbar: #{err}"
    process.exit -2

readNavMap = (navMap) ->
  # ncx navMap
  toc = []
  for np in navMap.navPoint
    entry = {title:''}
    for nl in np.navLabel
      for t in nl.text
        entry.title += t
    for c in np.content when c.$.src?
      entry.src = c.$.src    
    if entry.src?
      entry.pageid = "p#{toc.length+1}"
      toc.push entry
      console.log "added TOC entry #{JSON.stringify entry}"
  toc
  
processEpub = (epubPackage,metadata,manifest,spine,navMap) ->
  title = firstMeta metadata,"dc:title"
  console.log "Processing epub #{title}..."

  creators = allMeta metadata,"dc:creator"
  contributors = allMeta metadata,"dc:contributor"
  publishers = allMeta metadata,"dc:publisher"
  rights = allMeta metadata,"dc:rights"
  dates = allMeta metadata,"dc:date"
  languages = allMeta metadata,"dc:language"

  coverImages = findCoverImages manifest

  appcacheFiles = []
  staticFiles = []
  
  data = 
    makeNavbar: makeNavbar
    title: title
    coverImages: coverImages
    creators: creators
    contributors: contributors
    publishers: publishers
    rights: rights
    dates: dates
    languages: languages

  landing = eco.render landingTemplate, data
  data.pages = [landing]
  # cover
  if coverImages.length > 0
    cover = eco.render coverTemplate, data
    data.pages.push cover
    # first only?!
    staticFiles.push coverImages[0]
  # about
  about = eco.render aboutTemplate, data
  data.pages.push about

  # TOC
  toc = readNavMap navMap
  data.toc = toc
  data.firstPageid = toc[0].pageid
  if cover?
    toc.splice 0,0,{title:'Cover', pageid:'cover'}
  toc.splice 0,0,{title:'Start here...', pageid:'landing'}
  tocpage = eco.render tocTemplate, data
  data.pages.push tocpage

  # body
  for entry,i in toc when entry.src?
    bodyfn = outdn+EPUBDIR+entry.src
    console.log "Read content file #{bodyfn}"
    src = fs.readFileSync bodyfn, 'utf8'
    pagedata = 
      title: entry.title
      pageid: entry.pageid
      previd: if i==0 then 'contents' else toc[i-1].pageid
      nextid: if i+1 < toc.length then toc[i+1].pageid else null
      makeNavbar: makeNavbar
    ix = src.indexOf '<body'
    if ix >= 0
      ix = src.indexOf '>',ix
    ix2 = src.indexOf '</body>'
    if ix>=0 and ix2>ix
      pagedata.html = src.substring ix+1, ix2
    else
      console.log "Error: extracting content from #{bodyfn}"
      process.exit -1

    # images; what about other types??
    staticFiles = staticFiles.concat (findFiles pagedata.html, 'src')
    # TODO links?

    page = eco.render bodyTemplate, pagedata
    data.pages.push page

  try
    html = eco.render htmlTemplate, data
  catch err
    console.log "Templating error (html): #{err}"
    process.exit -2

  htmlfn = outdn+"/index.html"
  console.log "Output HTML file #{htmlfn}"
  fs.writeFileSync htmlfn, html

  # src & href from html.eco
  appcacheFiles = appcacheFiles.concat (findFiles htmlTemplate,'src')
  appcacheFiles = appcacheFiles.concat (findFiles htmlTemplate,'href')

  # copy/link static files
  for fn in staticFiles
    try 
      dfn = decodeURI fn
      tofile = outdn+"/"+dfn
      fromfile = outdn+EPUBDIR+dfn
      if not fs.existsSync tofile
        console.log "Try to link static file #{fn}"
        mkpdirs tofile
        fs.linkSync fromfile, tofile
      # encoded in appcache?
      appcacheFiles.push fn
    catch err
      console.log "Error copying/linking static file #{fromfile} to #{tofile}"	

  manifestfn = outdn+"/index.appcache"
  console.log "Writing #{manifestfn}"
  manifest = 'CACHE MANIFEST\n'+
    '# '+(new Date())+'\n'+
    '../css/images/ajax-loader.gif\n'+
    'index.html\n'
  for f in appcacheFiles
    manifest += f+'\n'

  fs.writeFileSync manifestfn, manifest


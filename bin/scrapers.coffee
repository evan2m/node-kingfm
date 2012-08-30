request = require('request')
cheerio = require('cheerio')
moment = require('moment')

mine_content = (content, selector, period, cb=null) ->
  # Scrapes the contents of dom, as filtered by the selector from a web page
    output = []
    $ = cheerio.load(content)
    $(selector).each (k,v) =>
      content = $(v).text()

      output.push(content) if content != ''
    if cb
          cb(output, period)

json_composer_name = (name, period) ->
  # Translate a composer name to lower case
  name
     # Remove Blank lines like [37]
    .replace(/^\[.*/, '')
    # Remove Nicknames in quotes
    .replace(/\ ".*"/g, '')
    # Remove all but the last word of the line
    .replace(/[^ ]* /g, '')
    # Convert to our json format
    .replace(/^(.*)/, '"$1": "' + period + '",')
    # Do comparisons in lowercase
    .toLowerCase()

process_names = (list, period) ->
  # Process a list of composer names and split them out
  res = (json_composer_name(name, period) for name in list)
  console.log(res)

fetch_content = (url, selector, period, cb) ->
  request.get(url, (error,response,body) ->
    if(error or response.statusCode != 200)
      console.log(error)
    else
      cb(body, selector, period, process_names)
  )

build_composer_db ->
  # Scrape wikipedia for composer name and period
  # Note, the file must be cleaned up afterwards to be valid json and to match king's
  # format
  # Just using console.log above for now

  fetch_content('http://en.wikipedia.org/wiki/List_of_Baroque_composers',
    'h2 ~ ul a',
    'baroque',
    mine_content)

  fetch_content('http://en.wikipedia.org/wiki/List_of_Classical_era_composers',
    'h2 ~ ul a',
    'classical',
    mine_content)

  fetch_content('http://en.wikipedia.org/wiki/List_of_Romantic-era_composers',
    '.wikitable tr td:first-child',
    'romantic',
    mine_content)

  fetch_content('http://en.wikipedia.org/wiki/List_of_20th-century_classical_composers_by_birth_date',
    '.wikitable tr td:first-child',
    'twentieth',
    mine_content)

parse_kingfm = (error, response, body) ->
  if(error or response.statusCode != 200)
    console.log(error)
  else
    $ = cheerio.load(body)

    # Pull the date for this playlist from the page itself to confirm it's correct
    playlist_date = $('.title').text()[13..]

    # Iterate over the playlist
    $('.date').each (k,v) =>
      song = {}
      $time = $(v)
      $row = $time.parent().parent()

      song['time'] = "#{playlist_date} #{$time.text().trim()}"
      song['composer'] = $row.find('.composer').text().trim()

      # Spit out csv data. We can convert to other formats afterward
      console.log("#{song['time']}\t#{song['composer']}")

fetch_playlist = (date) ->
  request.get("http://www.king.org/pages/4399266.php?npDate=#{date}", parse_kingfm)

build_playlist_db(days) ->

  today = moment().format('MMDD')

  # Pull 30 days worth of data
  dates = (moment().subtract('days', n).format('MMDD') for n in [days..0])

  fetch_playlist d for d in dates

build_playlist_db(30)

fs = require('fs')
moment = require('moment')

playlist = JSON.parse(fs.readFileSync('db/playlist.json'))
periods = JSON.parse(fs.readFileSync('db/composers.json'))

composers_by_air_time = (playlist, daytime=false) ->

  dates = []
  map = {}

  for date, composer of playlist
    # Build an array of timestampsalong with a mapping from timestamp to composer
    mom = moment(date, 'MM/DD/YYYY hh:mma')
    # Include only daytime hours
    unix_date = mom.unix()

    dates.push(unix_date)

    # Map to the composer whose work STARTED at this timestamp
    map[unix_date] = composer

  # Sort the dates so we can subtract adjacent members
  dates.sort

  results = {}

  for idx, date of dates when idx > 0
    # Subtract each item from its predecessor, ignoring the first
    prev_date = dates[idx - 1]
    difference = date - prev_date
    composer = map[prev_date]

    if results[composer] > 0
      results[composer] += difference
    else
      results[composer] = difference

  # csv output
  #console.log("#{k}\t#{v}") for k,v of results
  return results

# Take the already grouped output instead of starting over
periods_by_air_time = (total_times_by_composer, periods) ->

  grouped = {}

  for composer, total_seconds of total_times_by_composer
    period = periods[composer]
    if grouped[period]
      grouped[period] += total_seconds
    else
      grouped[period] = total_seconds

  return grouped

composers_by_play_count = (playlist) ->

  grouped = {}

  for time, composer of playlist
    if grouped[composer]
      grouped[composer] += 1
    else
      grouped[composer] = 1

  return grouped

periods_by_play_count = (playlist, periods) ->

  grouped = {}

  for time, composer of playlist
    period = periods[composer]
    if grouped[period]
      grouped[period] += 1
    else
      grouped[period] = 1

  return grouped

# Print results to console
console.log("Total airtime by composer")
total_times_by_composer = composers_by_air_time(playlist, periods)
console.log(total_times_by_composer)
console.log("Total airtime by period")
console.log(periods_by_air_time(total_times_by_composer, periods))
#console.log("Total play_count by composer")
#console.log(composers_by_play_count(playlist))
#console.log("Total play_count by period")
#console.log(periods_by_play_count(playlist, periods))

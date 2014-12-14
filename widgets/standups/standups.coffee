class Dashing.Standups extends Dashing.Widget
  ready: ->
    if @get('unordered')
      $(@node).find('ol').remove()
      if @get('sizestyle') is "three"
        $(@node).find('.two').remove()
    else
      $(@node).find('ul').remove()

  onData: (data) ->
  	console.log('inside standups data=' + JSON.stringify(data))

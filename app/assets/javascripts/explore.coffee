$(document).ready ->
  if q = urlParams.q
    s = $('[data-behavior~=explore_search_field]')
    s.val(q)
    k = ->
      s.keyup()
    k
    setTimeout k, 1

  $(document).on 'click', '[data-behavior~=explore_src_pick]', ->
    t = $(this)
    b = $('[data-behavior~=explore_src_pick_bar]')
    src = t.data 'src-name'
    activeClasses = 'bg-orange bold'
    b.find('[data-src-name=' + b.data('src-selected') + ']').toggleClass activeClasses
    t.toggleClass(activeClasses) if b.data('src-selected') isnt src or !t.attr('class').match(activeClasses)
    b.data 'src-selected', src
    $('[data-behavior~=explore_search_field]').keyup()

  $('[data-behavior~=explore_src_pick][data-src-name=nyt]').click()

  searchActions = ->
    if q = _.trim(this.value)
      r = $('[data-behavior~=explore_results_container]')
      r.html null
      r.removeClass 'center'
      r.addClass 'busy busy-large mx-auto'

      s = $('[data-behavior~=explore_src_pick_bar]').data 'src-selected'

      if urlParams.q && window.history.replaceState
        u = window.location.search.match(/([^&=]+)=?([^&]*)/g)[0].replace urlParams.q, q
        window.history.replaceState null, null, u
      else if window.history.replaceState
        window.history.replaceState null, null, '?q=' + q

      u = '/explore/results?src=' + s + '&q=' + q

      $.get u, (t) ->
        r.removeClass 'busy busy-large mx-auto'
        r.html t
        $('[data-behavior~=modal_trigger]').leanModal()

  $('[data-behavior~=explore_search_field]').on 'keyup', _.debounce(searchActions, 400)

  clippingFinished = (b, id) ->
    b.attr 'data-behavior', null
    b.attr 'href', '/recipes/' + id
    b.removeClass 'bg-blue busy'
    b.attr 'style', 'color: #0086eb; box-shadow: inset 0 0 0 2px #0092ff;'
    b.text 'Clipped!'

  $(document).on 'click', '[data-behavior~=explore_clip_from_list]', ->
    t = $(this)
    t.text null
    t.toggleClass 'bg-blue busy mx-auto'

    $.get '/save?url=' + t.closest('[data-behavior~=explore_result_item]').data('url'), (s) ->
      clippingFinished t, s

  $(document).on 'click', '[data-behavior~=explore_preview]', ->
    t = $(this)
    p = t.parent()

    r = p.closest '[data-behavior~=explore_result_item]'
    u = r.data 'url'
    $('[data-behavior~=explore_clip_from_preview]').data 'url', u
    $('[data-behavior~=explore_open_original]').attr 'href', u

    if n = _.trim r.data 'title'
      $('[data-behavior~=explore_preview_title]').text n

    b = $('[data-behavior~=explore_src_pick_bar]').data 'src-selected'
    s = if b is 'nyt' then 'NYT Cooking' else _.capitalize b
    $('[data-behavior~=explore_preview_description]').text 'Recipe from ' + s

    c = $('[data-behavior~=explore_preview_body]')
    c.html null
    c.addClass 'busy busy-large mx-auto'

    $.get '/explore/preview?url=' + u, (d) ->
      c.removeClass 'busy busy-large mx-auto'
      c.html d

  $(document).on 'click', '[data-behavior~=explore_clip_from_preview]', ->
    t = $(this)
    t.text null

    t.attr 'class', 'btn busy block mt2 mx-auto'

    u = t.data 'url'

    $.get '/save?url=' + u, (s) ->
      t.attr 'class', 'block bold mt2 link-reset'
      t.text 'Clipped!'

      p = $("[data-behavior~=explore_result_item][data-url='#{u}']")
      p = p.find '[data-behavior~=explore_clip_from_list]'
      clippingFinished p, s

      c = ->
        $('.modal-overlay').fadeOut 200
        $('#preview').css 'display': 'none'
        t.text 'Clip'
        t.attr 'class', 'btn bg-blue mt2'
      setTimeout c, 600
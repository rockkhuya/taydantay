#= require_self
#= require_tree .

window.Neighborly =
  configs:
    turbolinks: true
    pjax: false
    respond_with:
      'Create': 'New'
      'Update': 'Edit'

  modules: -> []

  initPage: ->
    unless window.Turbolinks is undefined
      $(document).bind "page:fetch", =>
        this.Loading.show()

      $(document).bind "page:restore", =>
        this.Loading.hide()

      $(document).bind "page:change", =>
        clearTimeout(this.flash_time_out)
        $(window).scrollTop(0)

        try
          FB.XFBML.parse()
        try
          twttr.widgets.load()

  init: ->
    $(document).foundation('reveal', {animation: 'fadeAndPop', animationSpeed: 100})
    $(document).foundation()
    this.flash.init()

    $.pjax.defaults.scrollTo = false if $.pjax.defaults?
    $.pjax.defaults.timeout = false if $.pjax.defaults?

    $('.button.disabled').click ->
      return false

    $('.top-bar .search-button').click ->
      if $('.discover-form-input').val() != ''
        $('form.discover-form').submit()
      else
        $('.discover-form-input').toggleClass('show').focus()

      return false

  Loading:
    show: ->
      $('#loading').addClass('show')
    hide: ->
      $('#loading').removeClass('show')

  flash:
    init: ->
      if $(".flash").length > 0
        this.flash_time_out = setTimeout(this.close, 5000)
        $(".flash a.close").click(this.close)

    close: ->
      $('.flash .alert-box').fadeOut('fast')
      setTimeout (->
        $('.flash').slideUp('slow')
      ), 100

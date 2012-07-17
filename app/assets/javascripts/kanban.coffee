class window.Kanban
  
  constructor: (options)->
    @projects = options.projects
    @queues = options.queues
    @renderTicket = Handlebars.compile($('#ticket_template').html())
    
    @observer = new Observer()
    self = @
    
    # Make the Kanban fill the browser window
    @kanban = $('#kanban')
    @window = $(window)
    @top = @naturalTop = @kanban.offset().top
    @window.resize => @setKanbanSize()
    @setKanbanSize()
    
    # Style alternating columns
    @kanban.find('thead tr th:even, tbody tr td:even, tfoot tr th:even').addClass('alt')
    
    # Fix the Kanban to the bottom of the window
    # after determining its natural top.
    @kanban.css('bottom': '0px')
    
    # It might be nice to calculate this
    # + 8 for 4px margin on all sides
    @standardTicketWidth = 2.7777778 * 18
    @standardTicketHeight = 1.8333333 * 18
    @standardPadding = 0.5 * 36
    @standardBorder = 0.1388889 * 36
    @standardMargin = 0.2222222 * 36
    
    # Set the size of tickets initially
    # Ticket description popover
    # window.console.log('[layout] init')
    $('.kanban-column').each ->
      self.resizeColumn $(@).find('ul:first')
      $(@).find('.ticket').popoverForTicket().pseudoHover().illustrateTicketVerdict()
    
    # Resize the tickets in a column when the window resizes
    $(window).resize ->
      # window.console.log('[layout] window resize')
      $('.kanban-column ul').each ->
        self.resizeColumn $(@)
  
  observe: (name, func)-> @observer.observe(name, func)
  unobserve: (name, func)-> @observer.unobserve(name, func)
  
  loadQueues: ->
    requests = []
    for queueName in @queues
      for project in @projects
        requests.push([project, queueName])
    
    nextRequest = =>
      request = requests.shift()
      if request
        [project, queueName] = request
        @loadQueue(project, queueName, nextRequest)
    
    # Send two requests at a time
    nextRequest()
    nextRequest()
  
  loadQueue: (project, queueName, callback)->
    $queue = $("##{queueName}")
    @fetchQueue project, queueName, (tickets)=>
      
      # Remove existing tickets
      $queue.find(".#{project.slug}").remove()
      
      for ticket in tickets
        $queue.append @renderTicket(ticket)
      
      @resizeColumn $queue
      
      $queue.find(".ticket.#{project.slug}")
        .popoverForTicket()
        .pseudoHover()
        .illustrateTicketVerdict()
      
      @observer.fire('queueLoaded', [queueName, project])
      callback() if callback
  
  fetchQueue: (project, queueName, callback)->
    xhr = @get "#{project.slug}/#{queueName}"
    xhr.error ->
      window.console.log('error', arguments)
    xhr.success (data, textStatus, jqXHR)->
      App.checkRevision(jqXHR)
      callback(data)
  
  setKanbanSize: ->
    height = @window.height() - @top
    @kanban.css(height: "#{height}px")
  
  showFullScreen: ->
    window.console.log('full screen')
    @top = 0
    @kanban.addClass('full-screen')
    @setKanbanSize()
  
  showNormal: ->
    window.console.log('normal')
    @top = @naturalTop
    @kanban.removeClass('full-screen')
    @setKanbanSize()
  
  urlFor: (path)->
    "#{App.relativeRoot()}/kanban/#{path}.json"
  
  get:  (path, params)-> @ajax(path,  'GET', params)
  post: (path, params)-> @ajax(path, 'POST', params)
  put:  (path, params)-> @ajax(path,  'PUT', params)
  ajax: (path, method, params)->
    url = @urlFor(path)
    $.ajax url,
      method: method
  
  resizeColumn: ($ul)->
    queue = $ul.attr('id')
    tickets = $ul.children().length
    
    $count = $("thead .kanban-column[data-queue=\"#{queue}\"]")
    $count.html("<strong>#{tickets}</strong> tickets")
    $count.toggleClass('zero', tickets == 0)
    
    return if tickets == 0
    
    $ul.removeClass('small-border')
    $ul.removeClass('small-margin')
    
    # This is obviously imprecise.
    # 60 is for the admin stripe and its bottom margin
    # 32 is for the THEAD which lists the number of tickets in a queue
    height = $(window).height() - 60 - 32 - $('tfoot').height()
    width = $ul.width()
    
    standardInnerWidth = @standardTicketWidth + @standardPadding
    standardTicketWidth = standardInnerWidth + @standardBorder + @standardMargin
    standardInnerHeight = @standardTicketHeight + @standardPadding
    standardTicketHeight = standardInnerHeight + @standardBorder + @standardMargin
    
    ratio = 1
    ticketWidth = standardTicketWidth
    ticketHeight = standardTicketHeight
    ticketsThatFitHorizontally = Math.floor(width / ticketWidth)
    
    if isNaN(ticketsThatFitHorizontally)
      window.console.log "[layout] #{ticketsThatFitHorizontally} tickets fit into ##{queue}"
      return
    
    while true
      numberOfRowsRequired = Math.ceil(tickets / ticketsThatFitHorizontally)
      heightOfTickets = numberOfRowsRequired * ticketHeight
      break if heightOfTickets < height
      
      # What ratio is required to squeeze one more column of tickets
      ticketsThatFitHorizontally++
      ticketWidth = Math.floor(width / ticketsThatFitHorizontally)
      ratio = ticketWidth / standardTicketWidth
      
      border = ratio * @standardBorder
      if border < 2
        $ul.addClass('small-border')
        border = 2
      
      margin = ratio * @standardMargin
      if margin < 2
        $ul.addClass('small-margin')
        margin = 2
      
      ratio = (ticketWidth - border - margin) / standardInnerWidth
      ticketHeight = (standardInnerHeight * ratio) + border + margin
    
    # window.console.log("[layout:#{queue}] column size: ", [width, height]) if queue == 'staged_for_testing'
    # window.console.log("[layout:#{queue}] ratio: #{ratio}") if queue == 'staged_for_testing'
    # window.console.log("[layout:#{queue}] tickets: #{ticketsThatFitHorizontally} rows x #{numberOfRowsRequired} cols") if queue == 'staged_for_testing'
    # window.console.log("[layout:#{queue}] ticket size: ", [ticketWidth, ticketHeight]) if queue == 'staged_for_testing'
    
    # At this point, get rid of the ticket age
    $ul.toggleClass('no-age', ratio < 0.666)
    
    # At this point, get rid of the ticket numbers
    $ul.toggleClass('no-number', ratio < 0.333)
    
    $ul.css('font-size': "#{ratio}em")

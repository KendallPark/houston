class window.TestingNoteView extends Backbone.View
  tagName: 'li'
  className: 'testing-note'
  
  events:
    'click .edit-note': 'edit'
    'click .destroy-note': 'destroy'
    'click .btn-cancel': 'cancel'
  
  initialize: ->
    @isInEditMode = false
    @renderTestingNote = HandlebarsTemplates['testing_notes/show']
    @renderEditTestingNote = HandlebarsTemplates['testing_notes/edit']
    $(@el).delegate 'form', 'submit', _.bind(@commit, @)
  
  render: ->
    $el = $(@el)
    $el.attr('id', "testing_note_#{@model.get('id')}")
    renderer = if @isInEditMode then @renderEditTestingNote else @renderTestingNote
    $el.html renderer(_.extend(@model.toJSON(), {editable: @isEditable(), tester: (window.user.get('role') == 'Tester')}))
    $el.attr('class', "testing-note #{@model.get('verdict')}")
    $el.addClass('by-tester') if @model.get('byTester')
    @
  
  isEditable: ->
    @model.get('userId') == window.userId or window.user.get('admin')
  
  edit: (e)->
    if e
      e.preventDefault()
      e.stopImmediatePropagation()
    if @isEditable() and !@isInEditMode
      @isInEditMode = true
      @render()
      @trigger('edit:begin', @)
    @
  
  commit: (e)->
    if e
      e.preventDefault()
      e.stopImmediatePropagation()
    if @isInEditMode
      $form = $(@el).find('form')
      $form.disable().find('.btn-primary').html('<i class="icon-spinner icon-spin"></i> Saving...')
      params = $form.serializeObject()
      previousAttributes = @model.previousAttributes()
      @model.save params,
        success: (model, response)=>
          @isInEditMode = false
          @render()
          @trigger('edit:commit', @, @model)
        error: (model, response)=>
          $form.enable().find('.btn-primary').html('Save')
          
          @model.set(previousAttributes, {silent: true})
          errors = Errors.fromResponse(response)
          if errors.missingCredentials or errors.invalidCredentials
            App.promptForCredentialsTo('Unfuddle')
          errors.renderToAlert().prependTo($(@el)).alert()
    @
  
  cancel: (e)->
    if e
      e.preventDefault()
      e.stopImmediatePropagation()
    if @isInEditMode
      @isInEditMode = false
      @render()
      @trigger('edit:cancel', @)
    @
  
  destroy: (e)->
    if e
      e.preventDefault()
      e.stopImmediatePropagation()
    @model.destroy
      success: =>
        @trigger('destroy', @, @model)
    @

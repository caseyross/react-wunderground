React = require 'react'

Autosuggest = require 'react-autosuggest'
IntuitiveTemperatureReadout = require './IntuitiveTemperatureReadout.cjsx'
WUAttribution = require './WUAttribution.cjsx'

fetchJsonp = require 'fetch-jsonp'
WUConfig = require '../config/wu.js'

module.exports = React.createClass

    getInitialState: ->
        search_text: ''
        suggestions: []
        weather: null

    updateSearchText: (event, { newValue }) ->
        @setState
            search_text: newValue

    updateSuggestions: ( { value } ) ->
        @getSuggestionsFromAPI value
        .then (suggestions) =>
            @setState
                suggestions: @getCities(suggestions)

    getCities: (suggestions) ->
        suggestions.filter (x) ->
            x.type == 'city'

    getSuggestionsFromAPI: (query) ->
        fetchJsonp 'https://autocomplete.wunderground.com/aq?query=' + query,
            jsonpCallback: 'cb'
        .then (res) ->
            if res.ok
                res.json()
            else
                throw new Error('Autocomplete API responded with an error')
        .then (json) ->
            json.RESULTS
        .catch (err) ->
            console.log err
            []

    chooseSuggestion: ( event, { suggestion } ) ->
        @getWeatherFromAPI suggestion.l
        .then (weather) =>
            console.log weather
            @setState
                weather: weather

    getWeatherFromAPI: (location) ->
        url = 'https://api.wunderground.com/api/' +
            WUConfig.API_KEY +
            '/almanac/astronomy/conditions/forecast/geolookup' +
            location +
            '.json'
        fetchJsonp url
        .then (res) ->
            if res.ok
                res.json()
            else
                throw new Error('Weather API responded with an error')
        .then (json) ->
            json
        .catch (err) ->
            console.log err
            null
            
    maybeRenderWeather: ->
        if @state.weather?
            <IntuitiveTemperatureReadout
                temp={ @state.weather.current_observation.feelslike_c }
                units='c'
            />
        else
            null
    
    render: ->
        <div>
            <Autosuggest
                suggestions={ @state.suggestions }
                onSuggestionsUpdateRequested={ @updateSuggestions }
                getSuggestionValue={ (suggestion) -> suggestion.name }
                renderSuggestion={ (suggestion) ->
                    <span>
                        { suggestion.name }
                    </span>
                }
                inputProps={
                    value: @state.search_text
                    onChange: @updateSearchText
                    type: 'search'
                    placeholder: 'Where?'
                }
                onSuggestionSelected={ @chooseSuggestion }
            />
            { @maybeRenderWeather() }
            <WUAttribution />
        </div>
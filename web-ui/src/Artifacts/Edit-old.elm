import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Markdown exposing (toHtml)
import Models exposing (Model, getArtifact, memberArtifact, getCreateArtifact)
import Styles exposing (warning)
import Artifacts.Models exposing (..)
import Messages exposing (createUrl, AppMsg(..), HelpPage(..))
import Artifacts.Messages exposing (..)
import Artifacts.View as View
import Artifacts.Select as Select
import Artifacts.Nav as Nav


{-| the entire view
-}
view : Model -> ViewOption -> Html AppMsg
view model option =
    let
        nav =
            if model.flags.readonly then
                Nav.bar model <| Nav.readBar
            else
                Nav.bar model <| Nav.editBar model option

        editing_head =
            h1 [ id "editing_head" ]
                [ text "Editing"
                , Nav.helpBtn HelpEdit False
                ]

        ( original, editing ) =
            case option of
                ReadChoice choice ->
                    ( [], [] )

                EditChoice choice ->
                    case choice of
                        ChangeChoice artifact _ ->
                            -- Header for original view
                            ( [ h1 [ id "original_head" ] [ text "Previous:" ]
                              , form model <| ReadChoice artifact
                              ]
                            , [ editing_head ]
                            )

                        CreateChoice _ ->
                            ( [], [ editing_head ] )
    in
        div [ viewIdAttr option ] <|
            List.concat
                [ [ nav ]
                , revisionWarnings model option
                , editing
                , [ form model option ]
                , original
                ]




form : Model -> ViewOption -> Html AppMsg
form model option =
    div [ class "m3" ]
        ((nameElements model option)
            ++ [ div [ class "clearfix py1" ]
                    [ formColumnOne model option
                    , formColumnTwo model option
                    ]
               ]
        )


{-| attributes column (non-text)
-}
formColumnOne : Model -> ViewOption -> Html AppMsg
formColumnOne model option =
    let
        partofEls =
            [ h3 []
                [ text "Partof"
                , Nav.helpBtn HelpPartof False
                ]
            , Select.partof model option
            ]

        elements =
            case option of
                ReadChoice artifact ->
                    -- display all information
                    [ View.completion artifact
                    , Select.defined model option
                    , View.implemented model artifact
                    , div [ class "clearfix py1" ]
                        [ div [ class "col col-6" ] partofEls
                        , div [ class "col col-6" ]
                            [ h3 []
                                [ text "Parts"
                                , Nav.helpBtn HelpParts False
                                ]
                            , View.parts model artifact
                            ]
                        ]
                    ]

                EditChoice choice ->
                    -- only display editable information
                    [ Select.defined model option
                    , doneFieldEdit model choice
                    ]
                        ++ partofEls
    in
        div [ class "col col-6" ] elements


{-| Text column
-}
formColumnTwo : Model -> ViewOption -> Html AppMsg
formColumnTwo model option =
    div [ class "col col-6" ]
        [ h3 []
            [ text "Text"
            , Nav.helpBtn HelpText False
            ]
        , selectRenderedBtns model option
        , div [ class "border border-black" ] [ displayText model option ]
        ]



-- NAME


nameElements : Model -> ViewOption -> List (Html AppMsg)
nameElements model option =
    let
        name_id =
            View.idAttr "name" option
    in
        case option of
            ReadChoice artifact ->
                [ h1 [ name_id ]
                    [ text artifact.name.raw
                    , Nav.helpBtn HelpName False
                    ]
                ]

            EditChoice choice ->
                let
                    edited =
                        getEdited choice

                    warn_els =
                        case Nav.checkName model edited.name choice of
                            Ok _ ->
                                []

                            Err e ->
                                [ warning e ]

                    editMsg t =
                        ArtifactsMsg <|
                            EditArtifact <|
                                setEdited choice { edited | name = t }

                    input_el =
                        div []
                            [ input
                                [ class "h1"
                                , name_id
                                , onInput editMsg
                                , value edited.name
                                ]
                                []
                            , Nav.helpBtn HelpName False
                            ]
                in
                    [ input_el ] ++ warn_els



-- TEXT


{-| select which text view to see (raw or rendered)
ids = {ed_, rd_}*text*{raw, rendered}
-}
selectRenderedBtns : Model -> ViewOption -> Html AppMsg
selectRenderedBtns model option =
    let
        newView render =
            let
                view =
                    model.state.textView
            in
                if isRead option then
                    { view | rendered_read = render }
                else
                    { view | rendered_edit = render }

        textView =
            model.state.textView

        --( rendered_clr, raw_clr ) =
        --    if isTextRendered model option then
        --        ( "black", "gray" )
        --    else
        --        ( "gray", "black" )
        ( rendered_clr, raw_clr ) =
            if isTextRendered model option then
                ( "btn-primary", "" )
            else
                ( "", "btn-primary" )

        cls =
            "btn "

        cls2 =
            " border border-black"
    in
        div []
            [ button
                -- rendered
                [ class (cls ++ rendered_clr ++ cls2)
                , id <| (View.idPrefix option) ++ "select_rendered_text"
                , onClick <| ArtifactsMsg <| ChangeTextViewState <| newView True
                ]
                [ text "rendered" ]
            , button
                -- raw
                [ class (cls ++ raw_clr ++ cls2)
                , id <| (View.idPrefix option) ++ "select_raw_text"
                , onClick <| ArtifactsMsg <| ChangeTextViewState <| newView False
                ]
                [ text "raw" ]
            ]


isTextRendered : Model -> ViewOption -> Bool
isTextRendered model option =
    let
        view =
            model.state.textView
    in
        if isRead option then
            view.rendered_read
        else
            view.rendered_edit



-- TEXT


displayText : Model -> ViewOption -> Html AppMsg
displayText model option =
    if isTextRendered model option then
        displayRenderedText model option
    else
        displayRawText model option


displayRenderedText : Model -> ViewOption -> Html AppMsg
displayRenderedText model option =
    let
        (rendered, partof) =
            case model.rendered of
                Just r ->
                    ( r.text, r.part)

                Nothing ->
                    ( "*Text is currently being rendered*"
                    , "*part is currently being rendered*"
                    )
    in
        div []
            [ toHtml [ View.idAttr "rendered_part" option ] partof
            , toHtml [ View.idAttr "rendered_text" option ] rendered
            ]


{-| display raw text in a way that can be edited
-}
displayRawText : Model -> ViewOption -> Html AppMsg
displayRawText model option =
    let
        ( rawText, editedAttrs ) =
            case option of
                ReadChoice artifact ->
                    ( artifact.text, [] )

                EditChoice choice ->
                    let
                        edited =
                            getEdited choice

                        changedMsg t =
                            ArtifactsMsg <|
                                EditArtifact <|
                                    setEdited choice { edited | text = t }
                    in
                        ( edited.text, [ onInput changedMsg ] )

        attrs =
            [ rows 35
            , cols 80
            , readonly <| isRead option
            , View.idAttr "raw_text" option
            ]
    in
        textarea (attrs ++ editedAttrs) [ text rawText ]



-- TODO: don't let the user define as done artifacts that are implemented!


doneFieldEdit : Model -> EditOption -> Html AppMsg
doneFieldEdit model option =
    let
        edited =
            getEdited option

        editMsg t =
            setEdited option { edited | done = t }
                |> EditArtifact
                |> ArtifactsMsg
    in
        div []
            [ span [ class "bold" ]
                [ text "Define as done:"
                , Nav.helpBtn HelpDone False
                ]
            , input
                [ View.idAttr "done" <| EditChoice option
                , onInput editMsg
                , value edited.done
                ]
                []
            ]


viewEditing : Model -> Html AppMsg
viewEditing model =
    let
        creating : List (Html AppMsg)
        creating =
            case model.create of
                Just c ->
                    [ li []
                        [ Nav.editBtn <| EditChoice <| CreateChoice c
                        , a
                            [ class "btn bold"
                            , id <| "CREATE_" ++ c.name
                            , onClick <| ArtifactsMsg <| CreateArtifact
                            , href <| "#" ++ createUrl
                            ]
                            [ text <| "Creating " ++ c.name ]
                        ]
                    ]

                Nothing ->
                    []

        line artifact =
            case artifact.edited of
                Just e ->
                    Just
                        (li []
                            [ Nav.editBtn <| EditChoice <| ChangeChoice artifact e
                            , View.seeArtifact model artifact
                            ]
                        )

                Nothing ->
                    Nothing

        lines =
            Dict.values model.artifacts
                |> List.filterMap line

        editing =
            ul []
                (creating ++ lines)

        header =
            h1
                [ class "h1" ]
                [ text "Artifacts you have not yet saved."
                , Nav.helpBtn HelpEdit False
                ]
    in
        div [ id "editing_view" ]
            [ Nav.bar model <| Nav.editingBar model
            , header
            , editing
            ]

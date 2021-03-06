module Views.GroupBar.Match exposing (jaro, jaroWinkler, commonPrefix)

import Utils.List exposing (zip)
import Char


{-|

    Adapted from https://blog.art-of-coding.eu/comparing-strings-with-metrics-in-haskell/
-}
jaro : String -> String -> Float
jaro s1 s2 =
    if s1 == s2 then
        1.0
    else
        let
            l1 =
                String.length s1

            l2 =
                String.length s2

            z2 =
                zip (List.range 1 l2) (String.toList s2)
                    |> List.map (Tuple.mapSecond Char.toCode)

            searchLength =
                -- A character must be within searchLength spaces of the
                -- character we are matching against in order to be considered
                -- a match.
                -- (//) is integer division, which removes the need to floor
                -- the result.
                ((max l1 l2) // 2) - 1

            m =
                zip (List.range 1 l1) (String.toList s1)
                    |> List.map (Tuple.mapSecond Char.toCode)
                    |> List.map (charMatch searchLength z2)
                    |> List.foldl (++) []

            ml =
                List.length m

            t =
                m
                    |> List.map (transposition z2 >> toFloat >> ((*) 0.5))
                    |> List.sum

            ml1 =
                toFloat ml / toFloat l1

            ml2 =
                toFloat ml / toFloat l2

            mtm =
                (toFloat ml - t) / toFloat ml
        in
            if ml == 0 then
                0
            else
                (1 / 3) * (ml1 + ml2 + mtm)


winkler : String -> String -> Float -> Float
winkler s1 s2 jaro =
    if s1 == "" || s2 == "" then
        0.0
    else if s1 == s2 then
        1.0
    else
        let
            l =
                commonPrefix s1 s2
                    |> String.length
                    |> toFloat

            p =
                0.1
        in
            jaro + ((l * p) * (1.0 - jaro))


jaroWinkler : String -> String -> Float
jaroWinkler s1 s2 =
    if s1 == "" || s2 == "" then
        0.0
    else if s1 == s2 then
        1.0
    else
        jaro s1 s2
            |> winkler s1 s2


commonPrefix : String -> String -> String
commonPrefix s1 s2 =
    if s1 == "" || s2 == "" then
        ""
    else if s1 == s2 then
        String.left 4 s1
    else
        cp (String.toList s1) (String.toList s2) []
            |> String.fromList


cp : List Char -> List Char -> List Char -> List Char
cp l1 l2 acc =
    if List.length acc == 4 then
        acc
    else
        case ( l1, l2 ) of
            ( x :: xs, y :: ys ) ->
                if x == y then
                    x :: cp xs ys acc
                else
                    acc

            _ ->
                acc


charMatch : number -> List ( number, number ) -> ( number, number ) -> List ( number, number )
charMatch matchRange list ( p, q ) =
    list
        |> List.drop (p - matchRange - 1)
        |> List.take (p + matchRange)
        |> List.filter (Tuple.second >> (==) q)


transposition : List ( number, number ) -> ( number, number ) -> Int
transposition list ( p, q ) =
    list
        |> List.filter
            (\( x, y ) ->
                p /= x && q == y
            )
        |> List.length

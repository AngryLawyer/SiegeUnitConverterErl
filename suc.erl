-module(suc).
-export([to_bmp/1, to_mut/1, many_to_mut/1, many_to_bmp/1]).

-define(MUT_DATA_LENGTH, 8192).
-define(MUT_HEADER, <<16#8,16#1,16#20,16#0,16#10,16#10>>).
-define(BMP_HEADER, <<"B":8/integer-little,
        "M":8/integer-little, %BMP file format
        9270:32/integer-little, %File size
        0:32/integer-little, %Unused
        1078:32/integer-little, %Offset
        40:32/integer-little, %Header size
        16:32/integer-little, %Width
        512:32/integer-little, %Height
        1:16/integer-little, %Colour planes
        8:16/integer-little, %Colour depth - 256 colour
        0:32/integer-little, %Compression
        8192:32/integer-little, %Image size
        0:32/integer-little, %Horizontal resolution
        0:32/integer-little, %Vertical resolution
        0:32/integer-little, %Colour palette count - 0 is autodetect
        0:32/integer-little %Important colours
        >>).

% Convert multiple BMPs to MUTs
many_to_mut(Filenames) ->
    lists:foreach(fun(Filename) -> io:fwrite("Parsing ~s~n", [Filename]), to_mut(Filename) end, Filenames).

% Convert multiple MUTs to BMPs
many_to_bmp(Filenames) ->
    lists:foreach(fun(Filename) -> io:fwrite("Parsing ~s~n", [Filename]), to_bmp(Filename) end, Filenames).

% Convert a valid MUT to a BMP file
to_bmp(Name) ->
    case string:str(string:to_lower(Name), ".mut") of
        0 -> io:fwrite("~p is not an MUT file~n", [Name]), error;
        _ ->
            {Status, Data} = file:read_file(Name),
            case Status of
                error -> io:fwrite("Failed to read file ~p for reason ~p~n", [Name, Data]), error;
                ok -> to_bmp2(Data, Name)
            end
    end.

to_bmp2(Data, Name) ->
    <<A, B, C, D, E, F, Rest/binary>> = Data,
    Rest_length = byte_size(Rest),
    case {<<A, B, C, D, E, F>>, Rest_length} of
        {?MUT_HEADER, ?MUT_DATA_LENGTH} -> to_bmp3(Rest, Name);
        _ -> io:fwrite("~p is an invalid MUT file.~n", [Name]), error
    end.

to_bmp3(Data, Name) ->
    Palette = parse_palette(),
    Output_name = change_filename_type(Name, "bmp"),
    case Palette of
        error -> io:fwrite("Failed to load siege.pal~n"), error;
        _ -> Image_data = reverse(Data), write_file(<<?BMP_HEADER/binary, Palette/binary, Image_data/binary>>, Output_name)
    end.


% Convert a valid BMP to a MUT file
to_mut(Name) ->
    case string:str(string:to_lower(Name), ".bmp") of
        0 -> io:fwrite("~p is not a BMP file~n", [Name]), error;
        _ ->
            {Status, Data} = file:read_file(Name),
            case Status of
                error -> io:fwrite("Failed to read file ~p for reason ~p~n", [Name, Data]), error;
                ok -> to_mut2(Data, Name)
            end
    end.

to_mut2(Data, Name) ->
    case validate_bmp_header(Data) of
        true ->
            Image_data = reverse(binary:part(Data, {byte_size(Data), -(?MUT_DATA_LENGTH)})),
            Output = <<?MUT_HEADER/binary, Image_data/binary>>,
            Output_name = change_filename_type(Name, "mut"),
            write_file(Output, Output_name);
        false -> io:fwrite("~p is not a compatiple BMP file.~n", [Name]), error
    end.


% Write some data to a file, but tell the world if it goes wrong 
write_file(Data, Output_name) ->
    Result = file:write_file(Output_name, Data),
    case Result of
        {error, Reason} -> io:fwrite("Failed to write ~p for reason ~p~n", [Output_name, Reason]), error;
        ok -> io:fwrite("Successfully wrote ~p~n", [Output_name]), ok
    end.

% Parse Siege.pal for a 256-color BMP palette
% Siege stores palette colours as little-endian tuples
parse_palette() ->
    {Status, Palette_data} = file:read_file("siege.pal"),
    case Status of
        error -> error;
        ok -> parse_palette_group(<<>>, Palette_data)
    end.
    
parse_palette_group(Palette_out, <<>>) ->
    reverse(Palette_out);
parse_palette_group(Palette_out, <<B, G, R, Rest/binary>>) ->
    parse_palette_group(<<0, B, G, R, Palette_out/binary>>, Rest).

%Check the important parts of the header
validate_bmp_header(Data) ->
    <<BM:16/integer-little,
      File_size:32/integer-little,
      _:32/integer-little,
      Offset:32/integer-little,
      Header_size:32/integer-little,
      Width:32/integer-little,
      Height:32/integer-little,
      _planes:16/integer-little,
      Depth:16/integer-little,
      _compression:32/integer-little,
      Image_size:32/integer-little,
      _Rest/binary>> = Data,
    case {BM, File_size, Offset, Header_size, Width, Height, Depth, Image_size} of
        {19778, 9270, 1078, 40, 16, 512, 8, 8192} -> true;
        _ -> false
    end.

% Change a file extension to whatever type we want
change_filename_type(Name, To) ->
    Period_pos = string:rchr(Name, $.),
    Stripped_string = string:substr(Name, 1, Period_pos),
    string:concat(Stripped_string, To).

% Binary reverse - from http://www.trapexit.org/forum/viewtopic.php?p=44362
reverse(Binary) ->
    Size = size(Binary)*8,
    <<T:Size/integer-little>> = Binary,
    <<T:Size/integer-big>>.

% Copyright (C) 2018 Alaskan Emily, Transnat Games.
%
% This software is provided 'as-is', without any express or implied warranty.
% In no event will the authors be held liable for any damages arising from
% the use of this software.
%
% Permission is granted to anyone to use this software for any purpose,
% including commercial applications, and to alter it and redistribute it
% freely, subject to the following restrictions:
%
%   1. The origin of this software must not be misrepresented; you must not
%      claim that you wrote the original software. If you use this software
%      in a product, an acknowledgment in the product documentation would be
%      appreciated but is not required.
%
%   2. Altered source versions must be plainly marked as such, and must not
%      be misrepresented as being the original software.
%
%   3. This notice may not be removed or altered from any source distribution.
%

:- module gearlib.cylinder.

%==============================================================================%
% Module to generate cylinders.
:- interface.
%==============================================================================%

%------------------------------------------------------------------------------%
% gen_cylinder(ConstructVertex(Position, TexCoord, Normal) = Vertex,
%   NumSides, Radius, Height) = IndexedMesh.
% Throws an exception if NumSides is less than 3.
%
% Some basic recommended side numbers:
% 5 the minimum "fart" setting. It looks a like a cylinder, unlike 3 or 4.
% 8 is a good "low-quality" setting, with normal interpolation is looks OK.
% 12 is a good "medium" setting.
% 16 is a good "high" setting.
:- func gen_cylinder(func(gearlib.v3, gearlib.v2, gearlib.v3) = Vertex,
    int, float, float) = (indexed_mesh(Vertex)).
:- mode gen_cylinder(func(in, in, in) = (out) is det,
    in, in, in) = (out) is det.

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module math.
:- import_module list.
:- import_module int.
:- import_module float.
:- import_module exception.

:- use_module gearlib.utils.

%------------------------------------------------------------------------------%
% gen_cylinder_part(ConstructVertex(Position, TexCoord, Normal) = Vertex,
%   Radius,
%   Height,
%   Increment,
%   Angle,
%   Lid1Vertex,
%   Lid2Vertex,
%   Face).
:- pred gen_cylinder_sides(func(gearlib.v3, gearlib.v2, gearlib.v3) = Vertex,
    float,
    float,
    float,
    float,
    int,
    int,
    list.list(int), list.list(int),
    list.list(Vertex), list.list(Vertex),
    int, int).
:- mode gen_cylinder_sides(func(in, in, in) = (out) is det,
    in,
    in,
    in,
    in,
    uo,
    uo,
    in, out,
    in, out,
    di, uo) is det.

gen_cylinder_sides(ConstructVertex,
    Radius,
    Height,
    Increment,
    Angle,
    I+1,
    I+0,
    Points, [I+2|[I+3|Points]],
    !Vertices,
    I, I+4) :-
    
    % Each step generates four vertices:
    % Lid1, Lid2, Side1, Side2
    % Since the list will be reversed, we must cons them in reverse order.
    list.cons(Lid2Vertex, !Vertices),
    list.cons(Lid1Vertex, !Vertices),
    list.cons(Side2Vertex, !Vertices),
    list.cons(Side1Vertex, !Vertices),
    
    Cos = math.cos(Angle),
    Sin = math.sin(Angle),
    
    % Positions.
    Pos = {Cos * Radius, Sin * Radius},
    Pos1 = gearlib.utils.z(Pos, Height *  0.5),
    Pos2 = gearlib.utils.z(Pos, Height * -0.5),
    
    % Tex coords for the lid.
    Tex = {Cos, Sin},
    
    % Normal for the sides
    Normal = gearlib.utils.z(Tex, 0.0),
    
    % S of tex-coords for the side.
    TexS = Angle / (math.pi + math.pi),
    
    Lid1Vertex = ConstructVertex(Pos1, Tex, gearlib.utils.z_antinormal),
    Lid2Vertex = ConstructVertex(Pos2, Tex, gearlib.utils.z_normal),
    Side1Vertex = ConstructVertex(Pos1, {TexS, 0.0}, Normal),
    Side2Vertex = ConstructVertex(Pos2, {TexS, 1.0}, Normal).

%------------------------------------------------------------------------------%

gen_cylinder(ConstructVertex, NumSides, Radius, Height) = indexed_mesh(
    list.reverse(Vertices),
    [fan(Lid1), fan(list.reverse(Lid2)), strip([2|[3|SidePoints]])]) :-
    
    gearlib.utils.angle_list(NumSides, Increment, Angles),
    
    list.map2_foldl3(gen_cylinder_sides(ConstructVertex, Radius, Height, Increment),
        Angles,
        Lid1,
        Lid2, % TODO: Which should be reversed?
        [], SidePoints,
        [], Vertices,
        0, Count).

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

:- module gearlib.gear.

%==============================================================================%
% Generates "flat" gears, which have two parallel sides.
% This is as opposed to bevel gears, which are meant to mesh at an angle.
:- interface.
%==============================================================================%

%------------------------------------------------------------------------------%
% gen_gear(ConstructVertex(Position, TexCoord, Normal) = Vertex,
%   NumTeeth, NumFacesPerToothSide, RootRadius, InsideRadius, Height) = IndexedMesh.
%
% Generates a mesh of a gear.
%
% The "RootRadius" is the radius of the circle that touches the top of each
% tooth.
% The "InsideRadius" is the radius of the circle that touches the bottom of
% each tooth.
%
% Throws an exception if NumFacesPerToothSide is less than 1 or NumTeeth
% less than 1.
:- func gen_gear(func(gearlib.v3, gearlib.v2, gearlib.v3) = Vertex,
    int, int, float, float, float) = (indexed_mesh(Vertex)).
:- mode gen_gear(func(in, in, in) = (out) is det,
    in, in, in, in, in) = (out) is det.

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
% QUICK GEAR GLOSSARY:
% 
% Root Radius: The radius including the teeth
% Inside Radius: The radius not including the teeth
% Top Land: The area on the top of the teeth
% Bottom Land: The area at the base of each tooth, which is the inside radius.
% 
% 
%

%------------------------------------------------------------------------------%

:- pred add_points(func(gearlib.v3, gearlib.v2, gearlib.v3) = Vertex,
    float, float, float, gearlib.v2, gearlib.v3, gearlib.v3, list.list(Vertex), list.list(Vertex)).
:- mode add_points(func(in, in, in) = (out) is det,
    in, in, in, in, in, in, in, out) is det.

add_points(ConstructVertex, X, Y, H, Tex, Normal1, Normal2, Vs, [V1|[V2|Vs]]) :-
    V1 = ConstructVertex({X, Y, H *  0.5}, Tex, Normal1),
    V2 = ConstructVertex({X, Y, H * -0.5}, Tex, Normal2).

%------------------------------------------------------------------------------%

:- pred add_points(func(gearlib.v3, gearlib.v2, gearlib.v3) = Vertex,
    float, float, float, gearlib.v2, gearlib.v3, list.list(Vertex), list.list(Vertex)).
:- mode add_points(func(in, in, in) = (out) is det,
    in, in, in, in, in, in, out) is det.

add_points(ConstructVertex, X, Y, H, Tex, Normal, !V) :-
    add_points(ConstructVertex, X, Y, H, Tex, Normal, Normal, !V).

%------------------------------------------------------------------------------%

:- pred add_points(func(gearlib.v3, gearlib.v2, gearlib.v3) = Vertex,
    float, float, float, float, list.list(Vertex), list.list(Vertex)).
:- mode add_points(func(in, in, in) = (out) is det,
    in, in, in, in, in, out) is det.

add_points(ConstructVertex, X, Y, H, Angle, !V) :-
    add_points(ConstructVertex, X, Y, H, Tex, gearlib.utils.z(Tex, 0.0), !V),
    Tex = {math.cos(Angle), math.sin(Angle)}.

%------------------------------------------------------------------------------%
% gen_cylinder_part(ConstructVertex(Position, TexCoord, Normal) = Vertex,
%   Radius,
%   PitchRadius,
%   Height,
%   Increment,
%   Angle,
%   Lid1Vertex,
%   Lid2Vertex,
%   Face).
:- pred gen_gear_tooth(func(gearlib.v3, gearlib.v2, gearlib.v3) = Vertex,
    float,
    float,
    float,
    float,
    float,
    list.list(face(int)), list.list(face(int)),
    list.list(int), list.list(int),
    list.list(int), list.list(int),
    list.list(Vertex), list.list(Vertex),
    int, int).
:- mode gen_gear_tooth(func(in, in, in) = (out) is det,
    in,
    in,
    in,
    in,
    in,
    in, out,
    in, out,
    in, out,
    in, out,
    di, uo) is det.

gen_gear_tooth(ConstructVertex,
    RootRadius,
    InsideRadius,
    Height,
    Increment,
    Angle,
    !Faces,
    !Lid1,
    !Lid2,
    !Vertices,
    I, I+24) :-
    
    % Normal calculation
    %
    %   |\
    %   |  \
    % R2|    \
    %   |      \
    %   |__V____T\
    %   |       /
    %   |      /
    %   |     /
    % R1|    / Ri
    %   |   /
    %   |  /
    %   |I/
    %   |/
    %
    % RootRadius is R1 + R2.
    % Ri is InsideRadius
    % Theta is the adjustment to add to Angle (represeted as vertical here).
    % I is the increment in angle between the top and bottom lands.
    %
    % Defining R1:
    % cos(I) = R1 / Ri,
    % R1 = cos(I) * Ri
    %
    % Defining R2:
    % R2 = RootRadius - R1,
    %
    % Defining T:
    % sin(I) = V / Ri
    % V = sin(I) * Ri
    % Ri = V / sin(I)
    % tan(T) = R2 / V
    % R2 = tan(T) * V
    % tan(T) = R2 / V
    %
    % tan(T) = R2 / (sin(I) * Ri)
    %
    % Substituting R1 for cos(I) * Ri
    % tan(T) = (RootRadius - R1) / (sin(I) * Ri)
    %
    % tan(T) = (RootRadius - (cos(I) * Ri)) / (sin(I) * Ri)
    %
    % Dividing both parts by Ri
    % tan(T) = ((RootRadius / Ri) - cos(I)) / sin(I)
    %
    % T = atan(((RootRadius / Ri) - cos(I)) / sin(I))
    
    RadiusScale = (RootRadius / InsideRadius),
    
    T = math.atan((RadiusScale - math.cos(Increment)) / math.sin(Increment)),
    
    % Each tooth consists of the following parts:
    % The bottom land end, the top land start, the top land end, and the bottom land start.
    % This means at angle 0.0, we are in the end of the final bottom land.
    
    QIncrement = (Increment * 0.25) + float.epsilon,
    % Bottom land end
    Angle1 = Angle,
    Sin1 = math.sin(Angle1),
    Cos1 = math.cos(Angle1),
    BottomEndX = Cos1 * InsideRadius,
    BottomEndY = Sin1 * InsideRadius,
    
    % Top land start
    Angle2 = Angle1 + QIncrement,
    Sin2 = math.sin(Angle2),
    Cos2 = math.cos(Angle2),
    TopStartX = Cos2 * RootRadius,
    TopStartY = Sin2 * RootRadius,
    
    % Top land end
    Angle3 = Angle2 + QIncrement,
    Sin3 = math.sin(Angle3),
    Cos3 = math.cos(Angle3),
    TopEndX = Cos3 * RootRadius,
    TopEndY = Sin3 * RootRadius,
    
    % Bottom land start
    Angle4 = Angle3 + QIncrement,
    Sin4 = math.sin(Angle4),
    Cos4 = math.cos(Angle4),
    BottomStartX = Cos4 * InsideRadius,
    BottomStartY = Sin4 * InsideRadius,
    
    % Normals for the rising and falling edges
    RisingNormal =  {math.cos(Angle + T), math.sin(Angle + T), 0.0},
    FallingNormal = {math.cos(Angle - T), math.sin(Angle - T), 0.0},
    
    % Face points
    add_points(ConstructVertex, BottomEndX, BottomEndY, Height, Angle1, !Vertices),
    list.cons(strip([I, I+1, I-2, I-1]), !Faces),

    add_points(ConstructVertex, BottomEndX, BottomEndY,     Height, {Cos1, Sin1}, RisingNormal, !Vertices),
    add_points(ConstructVertex, TopStartX, TopStartY,       Height, {Cos2, Sin2}, RisingNormal, !Vertices),
    list.cons(strip([I+ 4, I+ 5, I+ 2, I+ 3]), !Faces),

    add_points(ConstructVertex, TopStartX, TopStartY,       Height, Angle2, !Vertices),
    add_points(ConstructVertex, TopEndX, TopEndY,           Height, Angle3, !Vertices),
    list.cons(strip([I+ 8, I+ 9, I+ 6, I+ 7]), !Faces),

    add_points(ConstructVertex, TopEndX, TopEndY,           Height, {Cos3, Sin3}, FallingNormal, !Vertices),
    add_points(ConstructVertex, BottomStartX, BottomStartY, Height, {Cos4, Sin4}, FallingNormal, !Vertices),
    list.cons(strip([I+12, I+13, I+10, I+11]), !Faces),

    % Lid points
    add_points(ConstructVertex, BottomEndX, BottomEndY, Height, {Sin1, Cos1},
        gearlib.utils.z_normal, gearlib.utils.z_antinormal, !Vertices),
    
    list.cons(I+14, !Lid1),
    list.cons(I+15, !Lid2),
    
    add_points(ConstructVertex, TopStartX, TopStartY, Height, {Sin2, Cos2},
        gearlib.utils.z_normal, gearlib.utils.z_antinormal, !Vertices),
    
    list.cons(I+16, !Lid1),
    list.cons(I+17, !Lid2),

    add_points(ConstructVertex, TopEndX, TopEndY, Height, {Sin3, Cos3},
        gearlib.utils.z_normal, gearlib.utils.z_antinormal, !Vertices),
    
    list.cons(I+18, !Lid1),
    list.cons(I+19, !Lid2),

    add_points(ConstructVertex, BottomStartX, BottomStartY, Height, {Sin4, Cos4},
        gearlib.utils.z_normal, gearlib.utils.z_antinormal, !Vertices),
    
    list.cons(I+20, !Lid1),
    list.cons(I+21, !Lid2),
    
    % Will be used by the next call.
    add_points(ConstructVertex, BottomStartX, BottomStartY, Height, Angle4, !Vertices).

%------------------------------------------------------------------------------%

gen_gear(ConstructVertex, NumTeeth, _NumFacesPerToothSide, RootRadius, InsideRadius, Height) =
    indexed_mesh(list.reverse(
        [ConstructVertex({0.0, 0.0, Height *  0.5}, {0.5, 0.5}, gearlib.utils.z_normal)|
        [ConstructVertex({0.0, 0.0, Height * -0.5}, {0.5, 0.5}, gearlib.utils.z_antinormal)|
        Vertices]]),
    [fan([Count|list.reverse([14|Lid1])])|[fan([Count+1|list.reverse([15|Lid2])])|Faces]]) :-
    
    gearlib.utils.angle_list(NumTeeth, Increment, Angles),
    
    list.foldl5(gen_gear_tooth(ConstructVertex, RootRadius, InsideRadius, Height, Increment),
        Angles,
        [], FacesUnwrapped,
        [], Lid1,
        [], Lid2,
        [], Vertices,
        0, Count),
        
        ( if
%            list.reverse(FacesUnwrapped) = [strip(Indices)|Tail]
            list.reverse(FacesUnwrapped) = [strip(Indices)|Tail]
        then
            Faces = [strip(list.map(gearlib.utils.wrap(Count), Indices))|Tail]
%            Faces = [strip(list.map(gearlib.utils.wrap(Count), Indices))|[]]
        else
            throw(software_error("Less than one face"))
        ).

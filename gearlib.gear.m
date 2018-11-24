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

:- use_module list.

%------------------------------------------------------------------------------%
% gen_gear(ConstructVertex(Position, TexCoord, Normal) = Vertex,
%   NumTeeth, NumFacesPerToothSide, Radius, ToothRadius, Height) = IndexedMesh.
%
% All faces produced by this are triangle fans.
%
% Throws an exception if NumFacesPerToothSide is less than 1 or NumTeeth
% less than 1.
:- func gen_gear(func(gearlib.v3, gearlib.v2, gearlib.v3) = Vertex,
    int, int, float, float, float) = (indexed_mesh(Vertex)).
:- mode gen_gear(func(in, in, in) = (out) is det,
    in, in, in, in) = (out) is det.

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

gen_gear(ConstructVertex(Position, TexCoord, Normal) = Vertex,
    NumTeeth, NumFacesPerToothSide, Radius, ToothRadius, Height) =
    indexed_mesh([Center1Vertex|[Center2Vertex|list.reverse(Vertices)]], [Lid1|[Lid2|Sides]]) :-
    

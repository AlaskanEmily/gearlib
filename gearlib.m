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

:- module gearlib.

%==============================================================================%
% Gearlib procedurally generates meshes of gears.
:- interface.
%==============================================================================%

:- include_module gearlib.cylinder.
:- include_module gearlib.utils.

:- use_module list.

%------------------------------------------------------------------------------%
% Use as arguments to the funcs to generate vertices.
:- type v2 == {float, float}.
:- type v3 == {float, float, float}.

%------------------------------------------------------------------------------%

:- type face(Vertex) --->
    fan(list.list(Vertex)) ;
    strip(list.list(Vertex)).

%------------------------------------------------------------------------------%
% Stores an indexed mesh.
:- type indexed_mesh(Vertex) --->
    indexed_mesh(list.list(Vertex), list.list(face(int))).

%------------------------------------------------------------------------------%
% Stores a non-indexed mesh.
% Use convert/2 to convert from an indexed mesh to a regular mesh.
:- type mesh(Vertex) --->
    mesh(list.list(face(Vertex))).

%------------------------------------------------------------------------------%
% convert(IndexedMesh) = (Mesh)
%
% Creates a non-indexed mesh from an indeed mesh.
:- func convert(indexed_mesh(Vertex)) = mesh(Vertex).

%==============================================================================%
:- implementation.
%==============================================================================%

%------------------------------------------------------------------------------%
% convert_face(Points, Indices) = (Face)
%
% Creates a non-indexed face from a set of indices.
:- func convert_face(list.list(Vertex), face(int)) = face(Vertex).

%------------------------------------------------------------------------------%

convert_face(Points, fan(Indices)) =
    fan(list.map(list.det_index0(Points), Indices)).

convert_face(Points, strip(Indices)) =
    strip(list.map(list.det_index0(Points), Indices)).

%------------------------------------------------------------------------------%

convert(indexed_mesh(Points, IndexedFaces)) =
    mesh(list.map(convert_face(Points), IndexedFaces)).

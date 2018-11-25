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

:- module gearlib.utils.

%==============================================================================%
% Semi-private predicates used to generate meshes.
% These are not particularly useful outside this module and its submodules.
:- interface.
%==============================================================================%

:- use_module list.

%------------------------------------------------------------------------------%
% Checks that an angle is less than Pi * 2.0.
% Used as the termination pred for list.series.
:- pred validate_angle(float::in) is semidet.

%------------------------------------------------------------------------------%
% advance_angle(Increment, Angle) = NewAngle.
%
% Returns A + B. Used as the generate func for list.series to generate angles.
%
% NOTE: This actually adds float.epsilon in addition to prevent being slightly
% under the value for validate_angle.
:- func advance_angle(float, float) = float.

%------------------------------------------------------------------------------%
% angle_list(Count) = Angles
%
% Evenly divides PI / 2 into Count angles
:- func angle_list(int) = list.list(float).

%------------------------------------------------------------------------------%
% angle_list(Count) = Angles
%
% Evenly divides PI / 2 into Count angles
:- pred angle_list(int::in, list.list(float)::out) is det.

%------------------------------------------------------------------------------%
% angle_list(Count, Increment, Angles)
%
% Evenly divides PI / 2 into Count angles.
%
% The difference of each angle is Increment.
:- pred angle_list(int::in, float::uo, list.list(float)::out) is det.

%------------------------------------------------------------------------------%
% Wraps an int to be in range of 0..Size.
% This is useful for fixing up indexed meshes that might need elements from the
% end of the vertex list.
:- func wrap(int, int) = int.

%------------------------------------------------------------------------------%

:- func z_normal = gearlib.v3.

%------------------------------------------------------------------------------%

:- func z_antinormal = gearlib.v3.

%------------------------------------------------------------------------------%

:- func z(gearlib.v2, float) = gearlib.v3.

%==============================================================================%
:- implementation.
%==============================================================================%

:- use_module math.
:- import_module float.
:- import_module int.

%------------------------------------------------------------------------------%

:- func pi2 = float.
pi2 = math.pi + math.pi.
:- pragma inline(pi2/0).

%------------------------------------------------------------------------------%

validate_angle(A) :- A < pi2.

%------------------------------------------------------------------------------%

advance_angle(N, A) = (A + N) + float.epsilon.

%------------------------------------------------------------------------------%

angle_list(Count) = Angles :-
    angle_list(Count, _Increment, Angles).

%------------------------------------------------------------------------------%

angle_list(Count, angle_list(Count)).

%------------------------------------------------------------------------------%

angle_list(Count,
    Increment + float.epsilon,
    list.series(0.0, validate_angle, advance_angle(Increment))) :-
    pi2 / float(Count) = Increment.

%------------------------------------------------------------------------------%

wrap(Count, I) = (Out) :-
    ( I < 0 ->      Out = I + Count
    ; I > Count ->  Out = I - Count
    ;               Out = I ).

%------------------------------------------------------------------------------%

z_normal = {0.0, 0.0, 1.0}.

%------------------------------------------------------------------------------%

z_antinormal = {0.0, 0.0, -1.0}.

%------------------------------------------------------------------------------%

z({X, Y}, Z) = {X, Y, Z}.

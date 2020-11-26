function [t, x] = simFunc_c0(p)
	measTime = [0;10];
	simTime = [2.22044604925031e-16;10];

	% Species initial quantities.
	x0 = [1;0];
	% Simulation.
	[t, x] = ode15s(@ODEsFunc_c0, simTime, x0, [], p);

	t(1) = 0;
	[~, idx] = intersect(t, measTime, 'stable');
	t = measTime;
	x = x(idx, :);
end
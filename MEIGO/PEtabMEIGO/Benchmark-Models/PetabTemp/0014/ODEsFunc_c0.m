function dx = ODEsFunc_c0(t, x, p)
	% Parameter mapping
	a0 = p(1);
	b0 = p(2);
	k1 = p(3);
	k2 = p(4);

	% Species mapping
	A = x(1);
	B = x(2);

	% Compartments initial sizes.
	compartment = 1;

	% Stoichiometries.
	stoich_fwd_A = 1;
	stoich_fwd_B = 1;
	stoich_rev_B = 1;
	stoich_rev_A = 1;

	dx = zeros(2, 1);
	% ODEs.
	dx(1) = (stoich_rev_A*compartment*k2*B) - (stoich_fwd_A*compartment*k1*A);
	dx(2) = (stoich_fwd_B*compartment*k1*A) - (stoich_rev_B*compartment*k2*B);
end
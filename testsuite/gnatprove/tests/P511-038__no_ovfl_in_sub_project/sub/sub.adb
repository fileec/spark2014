procedure Sub (X, Y : in out Integer) with
  Pre  => X = Integer'Last and Y = 1,
  Post => X + Y - 1 = Integer'Last
is
begin
  null;
end Sub;

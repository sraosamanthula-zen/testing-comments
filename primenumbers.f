program x
  ! Declare real arrays a, b, x, y and real variable t
  real a(10,10), b(10), x(10), y(10), t
  ! Declare integer variables i, j, n
  integer i, j, n

  ! Read the value of n from input
  read(*,*) n

  ! Read the n x n matrix a from input
  do i = 1, n
    do j = 1, n
      read(*,*) a(i,j)
    end do
  end do

  ! Read the vector b from input and initialize vector x to zero
  do i = 1, n
    read(*,*) b(i)
    x(i) = 0.0
  end do

  ! Iterative process to solve the linear equations
  do 1 i = 1, 100
    ! Initialize y with values from b
    do j = 1, n
      y(j) = b(j)
    end do

    ! Adjust y based on current values of x and matrix a
    do j = 1, n
      do i = 1, n
        if (i.ne.j) then
          y(j) = y(j) - a(j,i) * x(i)
        end if
      end do
    end do

    ! Update x using the adjusted y and diagonal elements of a
    do j = 1, n
      x(j) = y(j) / a(j,j)
    end do
1   continue

  ! Output the computed vector x
  do i = 1, n
    write(*,*) x(i)
  end do
end
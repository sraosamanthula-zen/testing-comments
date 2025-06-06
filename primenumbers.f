! File Overview:
! This Fortran program solves a system of linear equations using an iterative method.
! It reads a matrix and a vector from input, then computes the solution vector x.
! The program is designed to address the business requirement of solving linear equations
! efficiently using an iterative approach suitable for small matrices.

program x
  ! Declare real arrays a, b, x, y and real variable t
  real a(10,10), b(10), x(10), y(10), t
  ! Declare integer variables i, j, n
  integer i, j, n

  ! Read the value of n from input, which determines the size of the matrix and vectors
  read(*,*) n

  ! Read the n x n matrix a from input
  ! The matrix 'a' represents the coefficients of the linear equations
  do i = 1, n
    do j = 1, n
      read(*,*) a(i,j)
    end do
  end do

  ! Read the vector b from input and initialize vector x to zero
  ! Vector 'b' represents the constants in the linear equations
  ! Vector 'x' is initialized to zero as the starting point for the iterative solution
  do i = 1, n
    read(*,*) b(i)
    x(i) = 0.0
  end do

  ! Iterative process to solve the linear equations using the Gauss-Seidel method
  ! The loop runs for a fixed number of iterations (100) to approximate the solution
  do 1 i = 1, 100
    ! Initialize y with values from b, which will be adjusted in the following steps
    do j = 1, n
      y(j) = b(j)
    end do

    ! Adjust y based on current values of x and matrix a
    ! This step computes the residuals by subtracting the influence of other variables
    do j = 1, n
      do i = 1, n
        if (i.ne.j) then
          y(j) = y(j) - a(j,i) * x(i)
        end if
      end do
    end do

    ! Update x using the adjusted y and diagonal elements of a
    ! This step updates the solution vector x using the computed residuals
    do j = 1, n
      x(j) = y(j) / a(j,j)
    end do
1   continue

  ! Output the computed vector x, which is the solution to the system of equations
  do i = 1, n
    write(*,*) x(i)
  end do
end
      ! This Fortran program solves a system of linear equations using an iterative method.
      ! The program reads a matrix and a vector from input, then iteratively refines the solution vector.
      ! It fulfills the requirement of computing the solution to linear equations, which can be used in various scientific and engineering applications.

      program x
      real a(10,10),b(10),x(10),y(10),t
      integer i,j,n

      ! Read the size of the matrix and vector
      read(*,*)n

      ! Read the matrix coefficients from input
      do i=1,n
        do j=1,n
          read(*,*)a(i,j)  ! Read each element of the matrix a from input
        end do
      end do

      ! Read the vector coefficients from input and initialize the solution vector to zero
      do i=1,n
        read(*,*)b(i)  ! Read each element of the vector b from input
        x(i)=0.0  ! Initialize each element of the solution vector x to zero
      end do

      ! Perform 100 iterations to refine the solution vector
      do 1 i=1,100
        ! Initialize the temporary vector y with the values of b
        do j=1,n
          y(j)=b(j)  ! Copy the vector b into y to start the iteration
        end do

        ! Adjust y by subtracting the influence of other variables based on the current solution x
        do j=1,n
          do i=1,n
            if(i.ne.j)then
              y(j)=y(j)-a(j,i)*x(i)  ! Subtract the influence of x(i) on y(j) using the matrix a
            end if
          end do
        end do

        ! Update the solution vector x using the adjusted values in y
        do j=1,n
          x(j)=y(j)/a(j,j)  ! Solve for x(j) by dividing y(j) by the diagonal element a(j,j)
        end do
1     continue

      ! Output the refined solution vector
      do i=1,n
        write(*,*)x(i)  ! Print each element of the solution vector x
      end do

      end
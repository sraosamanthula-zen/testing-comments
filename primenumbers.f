! This Fortran program solves a system of linear equations using the Gauss-Seidel method.
      ! It reads matrix coefficients and constant terms from input, iteratively computes the solution vector, and outputs the results.
      program x
      real a(10,10),b(10),x(10),y(10),t
      integer i,j,n

      ! Read the number of equations (n) from input
      read(*,*)n

      ! Read the coefficients of the matrix 'a' from input
      do i=1,n
        do j=1,n
          read(*,*)a(i,j)
        end do
      end do

      ! Read the constant terms vector 'b' from input and initialize solution vector 'x' to zero
      do i=1,n
        read(*,*)b(i)
        x(i)=0.0
      end do

      ! Perform Gauss-Seidel iterations up to 100 times
      do 1 i=1,100
        ! Initialize temporary vector 'y' with constant terms 'b'
        do j=1,n
          y(j)=b(j)
        end do

        ! Update 'y' by subtracting the non-diagonal elements' contribution
        do j=1,n
          do i=1,n
            if(i.ne.j)then
              y(j)=y(j)-a(j,i)*x(i)
            end if
          end do
        end do

        ! Compute the new values for the solution vector 'x'
        do j=1,n
          x(j)=y(j)/a(j,j)
        end do
1     continue

      ! Output the computed solution vector 'x'
      do i=1,n
        write(*,*)x(i)
      end do

      end
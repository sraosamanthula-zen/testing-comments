! This Fortran program solves a system of linear equations using the Gauss-Seidel iterative method.
      ! It reads a matrix 'a' and a vector 'b' from input, and computes the solution vector 'x'.
      ! The program fulfills the requirement of solving linear systems in a straightforward manner.

      program x
      real a(10,10),b(10),x(10),y(10),t
      integer i,j,n

      ! Read the number of equations 'n' from input
      read(*,*)n

      ! Read the coefficients of the matrix 'a' from input
      do i=1,n
        do j=1,n
          read(*,*)a(i,j)
        end do
      end do

      ! Read the vector 'b' from input and initialize the solution vector 'x' to zero
      do i=1,n
        read(*,*)b(i)
        x(i)=0.0
      end do

      ! Perform up to 100 iterations of the Gauss-Seidel method
      do 1 i=1,100
        ! Initialize the temporary vector 'y' with the values of 'b'
        do j=1,n
          y(j)=b(j)
        end do

        ! Update 'y' by subtracting the influence of other variables
        do j=1,n
          do i=1,n
            if(i.ne.j)then
              y(j)=y(j)-a(j,i)*x(i)
            end if
          end do
        end do

        ! Update the solution vector 'x' using the diagonal elements of 'a'
        do j=1,n
          x(j)=y(j)/a(j,j)
        end do
1     continue

      ! Output the solution vector 'x'
      do i=1,n
        write(*,*)x(i)
      end do

      end
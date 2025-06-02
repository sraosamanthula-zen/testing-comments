! This Fortran program solves a system of linear equations using the Gauss-Seidel iterative method.
      ! It reads a matrix 'a' and a vector 'b', then iteratively computes the solution vector 'x'.
      ! The business requirement fulfilled by this program is to provide a numerical solution to linear systems.

      program x
      real a(10,10),b(10),x(10),y(10),t
      integer i,j,n

      ! Read the size of the matrix and vectors
      read(*,*)n

      ! Read the matrix 'a' of size n x n
      do i=1,n
        do j=1,n
          read(*,*)a(i,j)
        end do
      end do

      ! Read the vector 'b' of size n and initialize the solution vector 'x' to zero
      do i=1,n
        read(*,*)b(i)
        x(i)=0.0
      end do

      ! Perform up to 100 iterations of the Gauss-Seidel method
      do 1 i=1,100
        ! Initialize the temporary vector 'y' with the current values of 'b'
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

        ! Update the solution vector 'x' using the current values of 'y'
        do j=1,n
          x(j)=y(j)/a(j,j)
        end do
1     continue

      ! Output the solution vector 'x'
      do i=1,n
        write(*,*)x(i)
      end do

      end
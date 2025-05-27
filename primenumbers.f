      program x
      real a(10,10),b(10),x(10),y(10),t
      integer i,j,n
      read(*,*)n
      do i=1,n
      do j=1,n
      read(*,*)a(i,j)
      end do
      end do
      do i=1,n
      read(*,*)b(i)
      x(i)=0.0
      end do
      do 1 i=1,100
      do j=1,n
      y(j)=b(j)
      end do
      do j=1,n
      do i=1,n
      if(i.ne.j)then
      y(j)=y(j)-a(j,i)*x(i)
      end if
      end do
      end do
      do j=1,n
      x(j)=y(j)/a(j,j)
      end do
1     continue
      do i=1,n
      write(*,*)x(i)
      end do
      end

MODULE trdmld_rst
   !!=================================================================================
   !!                       ***  MODULE  trdmld_rst  ***
   !! Ocean dynamic :  Input/Output files for restart on mixed-layer diagnostics
   !!=================================================================================
   !! History :  9.0  ! 05-05 (C. Deltel) Original code
   !!---------------------------------------------------------------------------------
#if defined key_trdmld
   !!---------------------------------------------------------------------------------
   USE dom_oce         ! ocean space and time domain
   USE trdmod_oce      ! ocean variables for trend diagnostics (i.e. icp/mixed-layer/vorticity)
   USE in_out_manager  ! I/O manager
   USE iom             ! I/O module

   IMPLICIT NONE
   PRIVATE
  
   PUBLIC   trd_mld_rst_read    ! routine called by trd_mld_init
   PUBLIC   trd_mld_rst_write   ! routine called by step.F90
  
   INTEGER ::   nummldw         ! logical unit for mld restart

   !!---------------------------------------------------------------------------------
   !! NEMO/OPA 3.3 , NEMO Consortium (2010)
   !! $Id: trdmld_rst.F90 3680 2012-11-27 14:42:24Z rblod $ 
   !! Software governed by the CeCILL licence (NEMOGCM/NEMO_CeCILL.txt)
   !!---------------------------------------------------------------------------------
  
CONTAINS
  
   SUBROUTINE trd_mld_rst_write( kt )
      !!--------------------------------------------------------------------------------
      !!                  ***  SUBROUTINE trd_mld_rst_wri  ***
      !!                
      !! ** Purpose :   Write mixed-layer diagnostics restart fields.
      !!--------------------------------------------------------------------------------
      INTEGER, INTENT( in ) ::   kt   ! ocean time-step index
      !
      CHARACTER (len=35) :: charout
      INTEGER ::   jk                 ! loop indice
      CHARACTER(LEN=20)   ::   clkt     ! ocean time-step deine as a character
      CHARACTER(LEN=255)  ::   clname   ! output restart file name
      !!--------------------------------------------------------------------------------

      ! to get better performances with NetCDF format:
      ! we open and define the ocean restart_mld file one time step before writing the data (-> at nitrst - 1)
      ! except if we write ocean restart_mld files every time step or if an ocean restart_mld file was writen at nitend - 1
      IF( kt == nitrst - 1 .OR. nstock == 1 .OR. ( kt == nitend .AND. MOD( nitend - 1, nstock ) == 0 ) ) THEN
         ! beware of the format used to write kt (default is i8.8, that should be large enough...)
         IF( nitrst > 999999999 ) THEN   ;   WRITE(clkt, *       ) nitrst
         ELSE                            ;   WRITE(clkt, '(i8.8)') nitrst
         ENDIF
         ! create the file
         clname = TRIM(crstdir_out)//'/'//TRIM(cexper)//"_"//TRIM(ADJUSTL(clkt))//"_"//TRIM(cn_trdrst_out)
         IF(lwp) THEN
            WRITE(numout,*)
            SELECT CASE ( jprstlib )
            CASE ( jprstdimg )   ;   WRITE(numout,*) '             open ocean restart_mld binary file: '//clname
            CASE DEFAULT         ;   WRITE(numout,*) '             open ocean restart_mld NetCDF file: '//clname
            END SELECT
            IF( kt == nitrst - 1 ) THEN   ;   WRITE(numout,*) '             kt = nitrst - 1 = ', kt,' date= ', ndastp
            ELSE                          ;   WRITE(numout,*) '             kt = '             , kt,' date= ', ndastp
            ENDIF
         ENDIF

         CALL iom_open( clname, nummldw, ldwrt = .TRUE., kiolib = jprstlib )
      ENDIF

      IF( kt == nitrst .AND. lwp ) THEN
         WRITE(numout,*)
         WRITE(numout,*) 'trdmld_rst: output for ML diags. restart, with trd_mld_rst_write routine kt =', kt
         WRITE(numout,*) '~~~~~~~~~~'
         WRITE(numout,*)
      ENDIF

      IF( ln_trdmld_instant ) THEN 
         !-- Temperature
         CALL iom_rstput( kt, nitrst, nummldw, 'tmlbb'           , tmlbb           )
         CALL iom_rstput( kt, nitrst, nummldw, 'tmlbn'           , tmlbn           )
         CALL iom_rstput( kt, nitrst, nummldw, 'tmlatfb'         , tmlatfb         )

         !-- Salinity
         CALL iom_rstput( kt, nitrst, nummldw, 'smlbb'           , smlbb           )
         CALL iom_rstput( kt, nitrst, nummldw, 'smlbn'           , smlbn           )
         CALL iom_rstput( kt, nitrst, nummldw, 'smlatfb'         , smlatfb         )
      ELSE
         CALL iom_rstput( kt, nitrst, nummldw, 'rmldbn'          , rmldbn          )

         !-- Temperature
         CALL iom_rstput( kt, nitrst, nummldw, 'tmlbn'           , tmlbn           )
         CALL iom_rstput( kt, nitrst, nummldw, 'tml_sumb'        , tml_sumb        )
         DO jk = 1, jpltrd
            IF( jk < 10 ) THEN   ;   WRITE(charout,FMT="('tmltrd_csum_ub_', I1)") jk
            ELSE                 ;   WRITE(charout,FMT="('tmltrd_csum_ub_', I2)") jk
            ENDIF
            CALL iom_rstput( kt, nitrst, nummldw, charout,  tmltrd_csum_ub(:,:,jk) )
         ENDDO
         CALL iom_rstput( kt, nitrst, nummldw, 'tmltrd_atf_sumb' , tmltrd_atf_sumb )

         !-- Salinity
         CALL iom_rstput( kt, nitrst, nummldw, 'smlbn'           , smlbn           )
         CALL iom_rstput( kt, nitrst, nummldw, 'sml_sumb'        , sml_sumb        )
         DO jk = 1, jpltrd
            IF( jk < 10 ) THEN   ;   WRITE(charout,FMT="('smltrd_csum_ub_', I1)") jk
            ELSE                 ;   WRITE(charout,FMT="('smltrd_csum_ub_', I2)") jk
            ENDIF
            CALL iom_rstput( kt, nitrst, nummldw, charout , smltrd_csum_ub(:,:,jk) )
         ENDDO
         CALL iom_rstput( kt, nitrst, nummldw, 'smltrd_atf_sumb' , smltrd_atf_sumb )
      ENDIF
      !
      IF( kt == nitrst ) THEN
         CALL iom_close( nummldw )     ! close the restart file (only at last time step)
         lrst_oce = .FALSE.
      ENDIF
      ! 
      !    
   END SUBROUTINE trd_mld_rst_write


   SUBROUTINE trd_mld_rst_read
    !!----------------------------------------------------------------------------
    !!                   ***  SUBROUTINE trd_mld_rst_lec  ***
    !!                   
    !! ** Purpose :   Read file for mixed-layer diagnostics restart.
    !!----------------------------------------------------------------------------
    INTEGER  ::  inum       ! temporary logical unit
    !
    CHARACTER (len=35) :: charout
    INTEGER ::   jk, nit000m1      ! loop indice
    INTEGER ::   jlibalt = jprstlib
    LOGICAL ::   llok
    CHARACTER(LEN=20)  :: clkt     ! ocean time-step define as a character
    CHARACTER(LEN=255) :: clname   ! restart file name
    !!-----------------------------------------------------------------------------

    IF(lwp)  THEN
       WRITE(numout,*)
       WRITE(numout,*) ' trd_mld_rst_read : read the NetCDF MLD restart file'
       WRITE(numout,*) ' ~~~~~~~~~~~~~~~~'
    ENDIF
    IF ( jprstlib == jprstdimg ) THEN
       ! eventually read netcdf file (monobloc)  for restarting on different number of processors
       ! if {cn_trdrst_in}.nc exists, then set jlibalt to jpnf90
       INQUIRE( FILE = TRIM(cn_trdrst_in)//'.nc', EXIST = llok )
       IF ( llok ) THEN ; jlibalt = jpnf90  ; ELSE ; jlibalt = jprstlib ; ENDIF
    ENDIF

!-lb
    !                                ! Open the namelist file 
    CALL ctl_opn( numnam, 'namelist', 'OLD', 'FORMATTED', 'SEQUENTIAL', -1, numout, lwp )

    CALL trd_mld_run_param
!-lb

    CALL iom_open( cn_trdrst_in, inum, kiolib = jlibalt )


    IF( ln_trdmld_instant ) THEN 
       !-- Temperature
       CALL iom_get( inum, jpdom_autoglo, 'tmlbb'           , tmlbb          )
       CALL iom_get( inum, jpdom_autoglo, 'tmlbn'           , tmlbn          )
       CALL iom_get( inum, jpdom_autoglo, 'tmlatfb'         , tmlatfb        )

       !-- Salinity
       CALL iom_get( inum, jpdom_autoglo, 'smlbb'           , smlbb          )
       CALL iom_get( inum, jpdom_autoglo, 'smlbn'           , smlbn          )
       CALL iom_get( inum, jpdom_autoglo, 'smlatfb'         , smlatfb        )
    ELSE
       CALL iom_get( inum, jpdom_autoglo, 'rmldbn'          , rmldbn         ) ! needed for rmld_sum

       !-- Temperature
       CALL iom_get( inum, jpdom_autoglo, 'tmlbn'           , tmlbn          ) ! needed for tml_sum
       CALL iom_get( inum, jpdom_autoglo, 'tml_sumb'        , tml_sumb       )
       DO jk = 1, jpltrd
          IF( jk < 10 )   THEN
             WRITE(charout,FMT="('tmltrd_csum_ub_', I1)") jk
          ELSE
             WRITE(charout,FMT="('tmltrd_csum_ub_', I2)") jk
          ENDIF
          CALL iom_get( inum, jpdom_autoglo, charout, tmltrd_csum_ub(:,:,jk) )
       ENDDO
       CALL iom_get( inum, jpdom_autoglo, 'tmltrd_atf_sumb' , tmltrd_atf_sumb)

       !-- Salinity
       CALL iom_get( inum, jpdom_autoglo, 'smlbn'           , smlbn          ) ! needed for sml_sum
       CALL iom_get( inum, jpdom_autoglo, 'sml_sumb'        , sml_sumb       )
       DO jk = 1, jpltrd
          IF( jk < 10 )   THEN
             WRITE(charout,FMT="('smltrd_csum_ub_', I1)") jk
          ELSE
             WRITE(charout,FMT="('smltrd_csum_ub_', I2)") jk
          ENDIF
          CALL iom_get( inum, jpdom_autoglo, charout, smltrd_csum_ub(:,:,jk) )
       ENDDO
       CALL iom_get( inum, jpdom_autoglo, 'smltrd_atf_sumb' , smltrd_atf_sumb)

       CALL iom_close( inum )
    ENDIF

  END SUBROUTINE trd_mld_rst_read

  SUBROUTINE trd_mld_run_param
     !!-------------------------------------------------------------------
     !!                  ***  ROUTINE trd_mld_run_param ***
     !!                 
     !! ** Purpose :   Definition some run parameter for trd_mld
     !!
     !! ** Method  :   Read the namtrd namelist 
     !!
     !! ** input   :   Namelist namtrd
     !!-------------------------------------------------------------------
     NAMELIST/namtrd/ nn_trd, nn_ctls, rn_ucf, cn_trdrst_in, cn_trdrst_out, &
        &             ln_trdmld_restart, ln_trdmld_instant
     CHARACTER(LEN=40) :: cl_no
     !!-------------------------------------------------------------------
     !                    
     REWIND( numnam )                      ! Read Namelist namtrd
     READ  ( numnam , namtrd )
     !
     WRITE(cl_no,*) nn_no-1 ; cl_no = TRIM(ADJUSTL(cl_no) )
     cn_trdrst_in= TRIM(cn_trdrst_in)//'-'//TRIM(cl_no)

     IF(ln_ens_rst_in) THEN
        cn_trdrst_in = TRIM(crstdir_in)//"/"//TRIM(cn_trdrst_in)//"."//TRIM(c_nmem)
     ELSE
        cn_trdrst_in = TRIM(crstdir_in)//"/"//TRIM(cn_trdrst_in)
     ENDIF
     !
  END SUBROUTINE trd_mld_run_param
  
#else
  !!=================================================================================
  !!                       ***  MODULE  trdmld_rst  ***
  !! Ocean dynamic :  Input/Output files for restart on mixed-layer diagnostics
  !!=================================================================================
CONTAINS
  SUBROUTINE trd_mld_rst_write( kt )           !  No ML diags ==> empty routine
    WRITE(*,*) 'trd_mld_rst_wri: You should not have seen this print! error?', kt
  END SUBROUTINE trd_mld_rst_write
  SUBROUTINE trd_mld_rst_read                  !  No ML Diags ==> empty routine
  END SUBROUTINE trd_mld_rst_read
#endif

  !!=================================================================================
END MODULE trdmld_rst

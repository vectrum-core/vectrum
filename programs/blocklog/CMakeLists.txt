add_executable( ${BLOCKLOG_EXECUTABLE_NAME} main.cpp )

if( UNIX AND NOT APPLE )
  set(rt_library rt )
endif()

find_package( Gperftools QUIET )
if( GPERFTOOLS_FOUND )
    message( STATUS "Found gperftools; compiling ${BLOCKLOG_EXECUTABLE_NAME} with TCMalloc")
    list( APPEND PLATFORM_SPECIFIC_LIBS tcmalloc )
endif()

target_include_directories( ${BLOCKLOG_EXECUTABLE_NAME} PUBLIC ${CMAKE_CURRENT_BINARY_DIR})

target_link_libraries( ${BLOCKLOG_EXECUTABLE_NAME}
        PRIVATE appbase
        PRIVATE eosio_chain fc ${CMAKE_DL_LIBS} ${PLATFORM_SPECIFIC_LIBS} )

copy_bin( ${BLOCKLOG_EXECUTABLE_NAME} )
install( TARGETS
   ${BLOCKLOG_EXECUTABLE_NAME}

   COMPONENT base

   RUNTIME DESTINATION ${CMAKE_INSTALL_FULL_BINDIR}
   LIBRARY DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR}
   ARCHIVE DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR}
)

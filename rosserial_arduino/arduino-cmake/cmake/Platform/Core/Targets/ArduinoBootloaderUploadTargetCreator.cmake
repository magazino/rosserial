

#=============================================================================#
# setup_arduino_bootloader_upload
# [PRIVATE/INTERNAL]
#
# setup_arduino_bootloader_upload(TARGET_NAME BOARD_ID PORT)
#
#      TARGET_NAME - target name
#      BOARD_ID    - board id
#      PORT        - serial port
#      AVRDUDE_FLAGS - avrdude flags (override)
#
# Set up target for upload firmware via the bootloader.
#
# The target for uploading the firmware is ${TARGET_NAME}-upload .
#
#=============================================================================#
function(create_arduino_bootloader_upload_target TARGET_NAME BOARD_ID PORT AVRDUDE_FLAGS)
    set(UPLOAD_TARGET ${TARGET_NAME}-upload)
    set(AVRDUDE_ARGS)

    build_arduino_bootloader_arguments(${BOARD_ID} ${TARGET_NAME} ${PORT} "${AVRDUDE_FLAGS}" AVRDUDE_ARGS)

    if (NOT AVRDUDE_ARGS)
        message("Could not generate default avrdude bootloader args, aborting!")
        return()
    endif ()

    if (NOT EXECUTABLE_OUTPUT_PATH)
        set(EXECUTABLE_OUTPUT_PATH ${CMAKE_CURRENT_BINARY_DIR})
    endif ()
    set(TARGET_PATH ${EXECUTABLE_OUTPUT_PATH}/${TARGET_NAME})

    list(APPEND AVRDUDE_ARGS "-Uflash:w:\"${TARGET_PATH}.hex\":i")
    list(APPEND AVRDUDE_ARGS "-Ueeprom:w:\"${TARGET_PATH}.eep\":i")
    
    _try_get_board_property(${BOARD_ID} upload.use_1200bps_touch USE_1200BPS_TOUCH)
    if (USE_1200BPS_TOUCH)  
        set(RESET_TARGET ${TARGET_NAME}-reset) 
        add_custom_target(${RESET_TARGET}
                          COMMAND stty -F ${PORT} ispeed 1200 ospeed 1200 
                          COMMAND sleep 2
                          COMMENT "Resseting board ${BOARD_ID} for flashing.")
    endif ()

    add_custom_target(${UPLOAD_TARGET}
                      ${ARDUINO_AVRDUDE_PROGRAM}
                      ${AVRDUDE_ARGS}
                      DEPENDS ${TARGET_NAME} ${RESET_TARGET})

    # Global upload target
    if (NOT TARGET upload)
        add_custom_target(upload)
    endif ()

    add_dependencies(upload ${UPLOAD_TARGET})
endfunction()

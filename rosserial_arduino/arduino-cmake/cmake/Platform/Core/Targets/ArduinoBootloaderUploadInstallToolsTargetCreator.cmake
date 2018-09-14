

#=============================================================================#
# create_arduino_bootloader_install_tools_target
# [PRIVATE/INTERNAL]
#
# create_arduino_bootloader_install_tools_target(TARGET_NAME BOARD_ID PORT)
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
function(create_arduino_bootloader_install_tools_target TARGET_NAME BOARD_ID PORT AVRDUDE_FLAGS)
    set(INSTALL_TOOLS_TARGET ${TARGET_NAME}-install-tools)
    set(AVRDUDE_ARGS)

    build_arduino_bootloader_arguments(${BOARD_ID} ${TARGET_NAME} "\$1" "${AVRDUDE_FLAGS}" AVRDUDE_ARGS)
    if (NOT AVRDUDE_ARGS)
        message("Could not generate default avrdude bootloader args, aborting!")
        return()
    endif ()
    #replace the avrdude.conf file path to relative for installation
    string(REPLACE "${ARDUINO_AVRDUDE_CONFIG_PATH}" "avrdude.conf" AVRDUDE_ARGS "${AVRDUDE_ARGS}")

    # This is set by the configure client directory
    if (NOT EXECUTABLE_OUTPUT_PATH)
        set(EXECUTABLE_OUTPUT_PATH ${CMAKE_CURRENT_BINARY_DIR})
    endif ()
    
    set(AVRDUDE_CONFIG_PATH ${EXECUTABLE_OUTPUT_PATH}/avrdude.conf)
    configure_file(${ARDUINO_AVRDUDE_CONFIG_PATH} ${AVRDUDE_CONFIG_PATH} COPYONLY)
    
    list(APPEND AVRDUDE_ARGS "-Uflash:w:\"${TARGET_NAME}.hex\":i")
    list(APPEND AVRDUDE_ARGS "-Ueeprom:w:\"${TARGET_NAME}.eep\":i")

    _try_get_board_property(${BOARD_ID} upload.use_1200bps_touch USE_1200BPS_TOUCH)
    if (USE_1200BPS_TOUCH)
        message(STATUS "Using reset method")     
        set(RESET_CMD "stty -F \$1 ispeed 1200 ospeed 1200")
    endif ()

    set(INSTALL_SCRIPT flash_${TARGET_NAME})
    add_custom_command(OUTPUT ${INSTALL_SCRIPT}
                       COMMAND echo "#!/bin/bash" > ${INSTALL_SCRIPT}
                       COMMAND echo "# This is an auto generated file from arduino-cmake ToolChain" >> ${INSTALL_SCRIPT}
                       COMMAND echo if [ -z \$1 ] >> ${INSTALL_SCRIPT}
                       COMMAND echo "then echo No port given, exitining" >> ${INSTALL_SCRIPT}
                       COMMAND echo exit 1 >> ${INSTALL_SCRIPT}
                       COMMAND echo fi >> ${INSTALL_SCRIPT}
                       COMMAND echo ${RESET_CMD} >> ${INSTALL_SCRIPT}
                       COMMAND echo sleep 2 >> ${INSTALL_SCRIPT}
                       COMMAND echo avrdude ${AVRDUDE_ARGS} >> ${INSTALL_SCRIPT}
                       COMMAND chmod u+x ${INSTALL_SCRIPT}
                       WORKING_DIRECTORY ${EXECUTABLE_OUTPUT_PATH}
                       COMMENT "Generating firmware flash script"
                       VERBATIM)

    add_custom_target(${INSTALL_TOOLS_TARGET}
                      DEPENDS ${TARGET_NAME} ${INSTALL_SCRIPT}
                      WORKING_DIRECTORY ${EXECUTABLE_OUTPUT_PATH}
                      COMMENT "building Install tools target"
                      VERBATIM)

endfunction()
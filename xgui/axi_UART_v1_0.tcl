# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "BAUD_DIV_FRAC_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "BAUD_DIV_INT_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "OVERSAMPLING_RATE" -parent ${Page_0}


}

proc update_PARAM_VALUE.BAUD_DIV_FRAC_WIDTH { PARAM_VALUE.BAUD_DIV_FRAC_WIDTH } {
	# Procedure called to update BAUD_DIV_FRAC_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BAUD_DIV_FRAC_WIDTH { PARAM_VALUE.BAUD_DIV_FRAC_WIDTH } {
	# Procedure called to validate BAUD_DIV_FRAC_WIDTH
	return true
}

proc update_PARAM_VALUE.BAUD_DIV_INT_WIDTH { PARAM_VALUE.BAUD_DIV_INT_WIDTH } {
	# Procedure called to update BAUD_DIV_INT_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BAUD_DIV_INT_WIDTH { PARAM_VALUE.BAUD_DIV_INT_WIDTH } {
	# Procedure called to validate BAUD_DIV_INT_WIDTH
	return true
}

proc update_PARAM_VALUE.OVERSAMPLING_RATE { PARAM_VALUE.OVERSAMPLING_RATE } {
	# Procedure called to update OVERSAMPLING_RATE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OVERSAMPLING_RATE { PARAM_VALUE.OVERSAMPLING_RATE } {
	# Procedure called to validate OVERSAMPLING_RATE
	return true
}


proc update_MODELPARAM_VALUE.BAUD_DIV_INT_WIDTH { MODELPARAM_VALUE.BAUD_DIV_INT_WIDTH PARAM_VALUE.BAUD_DIV_INT_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BAUD_DIV_INT_WIDTH}] ${MODELPARAM_VALUE.BAUD_DIV_INT_WIDTH}
}

proc update_MODELPARAM_VALUE.BAUD_DIV_FRAC_WIDTH { MODELPARAM_VALUE.BAUD_DIV_FRAC_WIDTH PARAM_VALUE.BAUD_DIV_FRAC_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BAUD_DIV_FRAC_WIDTH}] ${MODELPARAM_VALUE.BAUD_DIV_FRAC_WIDTH}
}

proc update_MODELPARAM_VALUE.OVERSAMPLING_RATE { MODELPARAM_VALUE.OVERSAMPLING_RATE PARAM_VALUE.OVERSAMPLING_RATE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OVERSAMPLING_RATE}] ${MODELPARAM_VALUE.OVERSAMPLING_RATE}
}


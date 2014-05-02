$(document).ready(
	function() {
		$('.time-input').timepicker();
		$('.duration-input').timepicker({   'timeFormat': 'H:i',
						    'minTime': '12:15am',
						    'maxTime': '11:30pm',
						    'step': 15
		})
});

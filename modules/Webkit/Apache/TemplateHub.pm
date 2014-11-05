package Webkit::Apache::TemplateHub;

################################
## Webkit::Apache::TemplateHub
#
# This module creates an in memory cache of all template data
# shared across all apache children.
#
# If you change this module, YOU MUST RESTART APACHE
# (login to ssh as admin, su, then 'sh httpd/restart.sh')


use strict qw(vars);

#use Apache::Constants qw(OK NOT_FOUND DECLINED);

my $logos = {
	1 => {
		src => '/images/logos/wk_window.gif',
		width => 82,
		height => 39 },

	2 => {
		src => '/images/logos/rbgc_window.gif',
		width => 156,
		height => 39 },

	31 => {
		src => '/images/logos/davidlock_window.gif',
		width => 77,
		height => 39 },

	25 => {
		src => '/images/logos/eaz_window.gif',
		width => 122,
		height => 39 },
		
	38 => {
		src => '/images/logos/busyview_window.gif',
		width => 122,
		height => 39 },

	16 => {
		src => '/images/logos/rk_window.gif',
		width => 101,
		height => 39 } };

my $frameset_attributes = {
	va_contacts_tree => {
		appname => 'va',
		left_title => 'Contacts Tree',
		left_method => 'contacts_tree',
		right_title => 'Contact Details',
		right_method => 'contact_details',
		width => 230 },

	va_jobs_tree => {
		appname => 'va',
		left_title => 'Projects Tree',
		left_method => 'jobs_tree',
		right_title => 'Project Details',
		right_method => 'job_details',
		width => 230 },

	resourceshare_main => {
		appname => 'resourceshare',
		left_title => 'Folders',
		left_method => 'resources_folder_tree',
		right_title => 'Resources',
		right_method => 'resources_welcome',
		width => 200 },

	easemail_main => {
		appname => 'easemail',
		left_title => 'Email Lists',
		left_method => 'easemail_list_tree',
		right_title => '',
		right_method => 'easemail_app_home',
		width => 200 },

	nctest_control_panel => {
		appname => 'nctest',
		left_method => 'control_panel_sidemenu',
		left_title => 'Info',
		width => 220,
		right_title => 'Working Area',
		right_method => 'control_panel_home' },

	nctest_tests_test_editor => {
		appname => 'nctest',
		left_title => 'Test Questions',
		left_method => 'tests_test_editor_tree',
		width => 163,
		right_frame_method => 'tests_test_editor_frameset' },

	nctest_marking => {
		appname => 'nctest',
		left_title => 'Marking Remaining',
		left_method => 'marking_marks_tree',
		width => 180,
		right_frame_method => 'marking_marks_frameset' },

	nctest_auto_marking_summary => {
		appname => 'nctest',
		left_title => 'Questions',
		left_method => 'analysis_auto_marking_tree',
		width => 180,
		right_frame_method => 'analysis_auto_marking_frameset' },

	nctest_progress_analysis => {
		appname => 'nctest',
		left_title => 'Pupils',
		left_method => 'analysis_progress_report_tree',
		width => 240,
		right_frame_method => 'analysis_progress_report_frameset' },

	eb_activities => {
		appname => 'eb',
		left_title => 'Activities',
		left_method => 'activity_tree',
		right_title => 'Activities',
		right_method => 'activity_home' }  };


## This hash holds all files that should be presented differently if Mac

my $mac_filepaths = {
	'/lib/app.css' => 1 };

##

my $templatedata = {
	app_defaults => { 				# THE TOP LEVEL (DEFAULTS)
		window => "window.htm",
		browser => "browser.htm",
		error => "error.htm",
		support_home => "support_home.htm",
		about_home => "about_home.htm",
		log_out => "log_out.htm",
		loading_anim => "loading_anim.htm",
		loading_div => "loading_div.htm",
		wrapper => "wrapper.htm",
		login => "login/login.htm",
		open_login_page => "login/open_login_page.htm",
		list_table => "list_table.htm",
		org_form => "org_form.htm",
		user_form => {
			default => "user_form.htm",
			mac => "user_form_mac.htm" },
		user_form_wrapper => "user_form_wrapper.htm",
		delete_confirm => "delete_confirm.htm",
		general_confirm => "general_confirm.htm",
		modal_message => "modal_message.htm",
		calendar => "calendar.htm",
		color_picker => "color_picker.htm",
		open_js_window => "open_js_window.htm",
		object_list => {
			default => "object_list.htm",
			mac => "object_list_mac.htm" },
		folder_list => "folder_list.htm",
		object_delete_confirm => "object_delete_confirm.htm",
		save_confirm => "save_confirm.htm",
		iframe_title => "iframe_title.htm",
		logged_in => "logged_in.htm",
		overrides => {
			org_16 => {
				login => "login/rk/login.htm"
			},
			org_25 => {
				login => "login/eaz/login.htm"
			},
			org_31 => {
				login => "login/davidlock/login.htm"
			},
			org_2 => {
				login => "login/rbgc2/login.htm"
			},
			org_38 => {
				login => "login/busyview/login.htm"
			}
		}
	},

	apps => {				# Each application
		app_pnctest => {
			open_login_page => "nctest/pupils/login.htm",
			bridge_login => "nctest/pupils/bridge_login.htm",
			login => "nctest/pupils/login.htm",
			wrapper => "nctest/pupils/wrapper.htm",
			launch => "nctest/pupils/launch.htm",
			test_frame => "nctest/pupils/test_frame.htm",
			instructions => "nctest/pupils/instructions.htm",
			sub_question_form => "nctest/sub_question_preview.htm",
			error => "nctest/pupils/error.htm",
			finished => "nctest/pupils/finished.htm",
			tree => "nctest/pupils/tree.htm",
			window => "nctest/pupils/window.htm",
		},

		app_wkfolders => {
			window => "wkfolders/window.htm",
			menu => "wkfolders/menu.xml",
			wrapper => "wkfolders/wrapper.htm" },

		app_firstcontact => {
			homepage => "firstcontact/homepage.htm",
			museum_history => "firstcontact/museum_history.htm",
			questionnaire_analysis => "firstcontact/questionnaire_analysis.htm",
			questionnaire_answers => "firstcontact/questionnaire_answers.htm",
			museum_form => "firstcontact/museum_form.htm",
			museum_login_form => "firstcontact/museum_login_form.htm",
			museum_login_home => "firstcontact/museum_login_home.htm",
			update_complete => "firstcontact/update_complete.htm",
			choose_museum => "firstcontact/choose_museum.htm",
			visitor_form => "firstcontact/visitor_form.htm",
			menu => "firstcontact/menu.xml",
			wrapper => "firstcontact/wrapper.htm",
			window => "firstcontact/window.htm" },

		app_testcontact => {
			contact_form => "testcontact/contact_form.htm",
			window => "testcontact/window.htm",
			menu => "testcontact/menu.xml" },

		app_nctest => {
			system_home => "nctest/system_home.htm",
			object_list => "nctest/object_list.htm",
			process_output => "nctest/process_output.htm",
			control_panel_home_toolbar => "nctest/control_panel_home_toolbar.htm",
			control_panel_sidebar_tree => "nctest/control_panel_sidebar_tree.htm",
			control_panel_intro => "nctest/control_panel_intro.htm",
			control_panel_home => "nctest/control_panel_home.htm",
			control_panel_generic_home => "nctest/control_panel_generic_home.htm",
			control_panel_edit => "nctest/control_panel_edit.htm",
			control_panel_assessment => "nctest/control_panel_assessment.htm",
			control_panel_pupils => "nctest/control_panel_pupils.htm",
			control_panel_invigilate => "nctest/control_panel_invigilate.htm",
			control_panel_finished => "nctest/control_panel_finished.htm",
			control_panel_marked => "nctest/control_panel_marked.htm",
			control_panel_processed => "nctest/control_panel_processed.htm",
			duplicate_test_form => "nctest/duplicate_test_form.htm",
			sub_question_choose_component_type => "nctest/sub_question_choose_component_type.htm",
			comment_component => "nctest/question_component_forms/comment.htm",
			question_component => "nctest/question_component_forms/question.htm",
			image_component => "nctest/question_component_forms/image.htm",
			textline_input => "nctest/question_input_forms/textline.htm",
			textbox_input => "nctest/question_input_forms/textbox.htm",
			numeric_range_input => "nctest/question_input_forms/numeric_range.htm",
			mchoice_checkboxes_input => "nctest/question_input_forms/mchoice_checkboxes.htm",
			keywords_input => "nctest/question_input_forms/keywords.htm",
			sum_input => "nctest/question_input_forms/sum.htm",
			multiword_input => "nctest/question_input_forms/multiword.htm",
			none_assessment => "nctest/assessment_types/none.htm",
			level_assessment => "nctest/assessment_types/level.htm",
			statement_assessment => "nctest/assessment_types/statement.htm",
			reception_assessment => "nctest/assessment_types/reception.htm",
			test_form => "nctest/test_form.htm",
			question_form => "nctest/question_form.htm",
			question_choose_assessment_type => "nctest/question_choose_assessment_type.htm",
			sub_question_form => "nctest/sub_question_form.htm",
			sub_question_preview => "nctest/sub_question_preview.htm",
			test_editor_tree => "nctest/test_editor_tree.htm",
			test_preview_tree => "nctest/test_preview_tree.htm",
			select_statement_of_ability => "nctest/select_statement_of_ability.htm",
			test_instructions_form => "nctest/test_instructions_form.htm",
			assessment_group_editor => "nctest/assessment_group_editor.htm",
			test_editor_home => "nctest/test_editor_home.htm",
			default_test_instructions => "nctest/default_test_instructions.htm",
			preview_style_sheet => "nctest/preview_style_sheet.htm",
			class_form => "nctest/class_form.htm",
			pupil_form => "nctest/pupil_form.htm",
			upload_pupils => "nctest/upload_pupils.htm",
			search_pupils => "nctest/search_pupils.htm",
			exam_marking_home => "nctest/exam_marking_home.htm",
			marking_tree => "nctest/marking_tree.htm",
			marking_toolbar => "nctest/marking_toolbar.htm",
			marking_auto_summary_tree => "nctest/marking_auto_summary_tree.htm",
			marking_auto_summary => "nctest/marking_auto_summary.htm",
			marking_manual_form => "nctest/marking_manual_form.htm",
			exam_marks_summary => "nctest/exam_marks_summary.htm",
			exam_form => "nctest/exam_form.htm",
			exam_choose_pupils => "nctest/exam_choose_pupils.htm",
			exam_class_choose_pupils => "nctest/exam_class_choose_pupils.htm",
			exam_manual_assessment_groups => "nctest/exam_manual_assessment_groups.htm",
			exam_sitting_form => "nctest/exam_sitting_form.htm",
			invigilators_home => "nctest/invigilators_home.htm",
			invigilators_form => "nctest/invigilators_form.htm",
			invigilators_login_codes => "nctest/invigilators_login_codes.htm",
			invigilators_print_login_codes => "nctest/invigilators_print_login_codes.htm",
			analysis_pupil_question_report => "nctest/analysis_pupil_question_report.htm",
			analysis_question_report => "nctest/analysis_question_report.htm",
			analysis_question_report_toolbar => "nctest/analysis_question_report_toolbar.htm",
			analysis_level_report => "nctest/analysis_level_report.htm",
			analysis_level_report_toolbar => "nctest/analysis_level_report_toolbar.htm",
			analysis_level_breakdown => "nctest/analysis_level_breakdown.htm",
			analysis_exam_level_breakdown => "nctest/analysis_exam_level_breakdown.htm",
			analysis_progress_report => "nctest/analysis_progress_report.htm",
			analysis_progress_report_toolbar => "nctest/analysis_progress_report_toolbar.htm",
			analysis_progress_report_mode_chooser => "nctest/analysis_progress_report_mode_chooser.htm",
			analysis_pupil_progress_report_toolbar => "nctest/analysis_pupil_progress_report_toolbar.htm",
			analysis_progress_topic_period_report => "nctest/analysis_progress_topic_period_report.htm",
			analysis_progress_subject_period_report => "nctest/analysis_progress_subject_period_report.htm",
			analysis_progress_report_tree => "nctest/analysis_progress_report_tree.htm",
			analysis_target_report => "nctest/analysis_target_report.htm",
			analysis_skill_statement_report => "nctest/analysis_skill_statement_report.htm",
			admin_remark_input => "nctest/admin_remark_input.htm",
			admin_show_zero_scores => "nctest/admin_show_zero_scores.htm",
			menu => "nctest/menu.xml",
			window => "nctest/window.htm" },

		app_vm => {				# The Holiday System
			menu => "vm/menu.xml",
			login => "vm/login.htm",
			delete_confirm => "vm/users_delete_confirm.htm",
			sidemenu => "vm/sidemenu.htm",
			list_users => "vm/list_users.htm",
			user_form_wrapper => "vm/user_form_wrapper.htm",
			holiday_form => "vm/holiday_form.htm",
			view_day => "vm/view_day.htm",
			view_month => "vm/view_month.htm",
			view_year => "vm/view_year.htm",
			pagetop => "vm/pagetop.htm",
			add_owed_days => "vm/add_owed_days.htm",
			delete_holiday => "vm/delete_holiday_confirm.htm",
			export_dates => "vm/export_dates.htm",
			window => "vm/window.htm"
		},

		app_dbtutor => {
			menu => "dbtutor/menu.xml",
			window => "dbtutor/window.htm" },

		app_myoffice2 => {
			print_tree => "myoffice2/print_tree.htm",
			print_toolbar => "myoffice2/print_toolbar.htm",
			print_form => "myoffice2/print_form.htm",
			print_sheet => "myoffice2/print_sheet.htm",
			print_not_assigned => "myoffice2/print_not_assigned.htm",
			deal_form => "myoffice2/deal_form.htm",
			deal_summary => "myoffice2/deal_summary.htm",
			modal_timeline_frame => "myoffice2/modals/modal_timeline_frame.htm",
			modal_timeline_page => "myoffice2/modals/modal_timeline_page.htm",
			modal_timeline_not_booked => "myoffice2/modals/modal_timeline_not_booked.htm",
			modal_search_venues_frame => "myoffice2/modals/modal_search_venues_frame.htm",
			modal_search_venues_page => "myoffice2/modals/modal_search_venues_page.htm",
			modal_assign_print_run => "myoffice2/modals/modal_assign_print_run.htm",
			modal_assign_tourdate_staff => "myoffice2/modals/modal_assign_tourdate_staff.htm",
			modal_find_showing_page => "myoffice2/modals/modal_find_showing_page.htm",
			modal_venue_status_search => "myoffice2/modals/modal_venue_status_search.htm",
			modal_venue_status_search_results => "myoffice2/modals/modal_venue_status_search_results.htm",
			editors_numbertext => "myoffice2/editors/number_text_editor.htm",
			editors_date => "myoffice2/editors/date_editor.htm",
			editors_multidate => "myoffice2/editors/multidate_editor.htm",
			editors_multidatenote => "myoffice2/editors/multidatenote_editor.htm",
			editors_notes => "myoffice2/editors/notes_editor.htm",
			editors_notes_date => "myoffice2/editors/notes_date_editor.htm",
			editors_multiprice => "myoffice2/editors/multiprice_editor.htm",
			editors_datetime => "myoffice2/editors/datetime_editor.htm",
			editors_daterange => "myoffice2/editors/daterange_editor.htm",
			booking_report_tree => "myoffice2/booking_report_tree.htm",
			booking_report_toolbar => "myoffice2/booking_report_toolbar.htm",
			booking_report_sheet => "myoffice2/booking_report_sheet.htm",
			booking_progress_tree => "myoffice2/booking_progress_tree.htm",
			booking_progress_sheet => "myoffice2/booking_progress_sheet.htm",
			booking_progress_sheet_toolbar => "myoffice2/booking_progress_sheet_toolbar.htm",
			booking_penciled_tree => "myoffice2/booking_penciled_tree.htm",
			booking_penciled_sheet => "myoffice2/booking_penciled_sheet.htm",
			booking_penciled_sheet_toolbar => "myoffice2/booking_penciled_sheet_toolbar.htm",
			tourlist_toolbar => "myoffice2/tourlist_sheet_toolbar.htm",
			tourlist_sheet => "myoffice2/tourlist_sheet.htm",
			tourlist_tree => "myoffice2/tourlist_tree.htm",
			sales_figures_toolbar => "myoffice2/sales_figures_toolbar.htm",
			sales_figures_sheet => "myoffice2/sales_figures_sheet.htm",
			sales_figures_tree => "myoffice2/sales_figures_tree.htm",
			showing_form => "myoffice2/showing_form.htm",
			main_homepage => "myoffice2/main_homepage.htm",
			main_homepage_tree => "myoffice2/main_homepage_tree.htm",
			venue_home => "myoffice2/venue_home.htm",
			venue_form => "myoffice2/venue_form.htm",
			venue_info_window => "myoffice2/venue_info_window.htm",
			venue_status_toolbar => "myoffice2/venue_status_toolbar.htm",
			venue_status_sheet => "myoffice2/venue_status_sheet.htm",
			venue_status_tree => "myoffice2/venue_status_tree.htm",
			timeline_tree => "myoffice2/timeline_tree.htm",
			tour_form => "myoffice2/tour_form.htm",
			menu => "myoffice2/menu.xml",
			wrapper => "myoffice2/wrapper.htm",
			window => "myoffice2/window.htm" },

		app_eb => {
			flatten_website => "eb/flatten_website.htm",
			download_custom_cd => "eb/download_custom_cd.htm",
			emailer_upload => "eb/emailer_upload.htm",
			emailer => "eb/emailer.htm",
			emailer_confirm => "eb/emailer_confirm.htm",
			account_csv_report => "eb/account_csv_report.htm",
			schools_disk_report => "eb/schools_disk_report.htm",
			options_home => "eb/options_home.htm",
			usage_report => "eb/usage_report.htm",
			thread_form => "eb/thread_form.htm",
			onlineclub_email_form => "eb/onlineclub_email_form.htm",
			activity_form => "eb/activity_form.htm",
			product_form => "eb/product_form.htm",
			product_invoice_form => "eb/product_invoice_form.htm",
			cd_product_invoice_form => "eb/cd_product_invoice_form.htm",
			online_product_invoice_form => "eb/online_product_invoice_form.htm",
			build_download_toolbar => "eb/build_download_toolbar.htm",
			supplier_product_invoice_form => "eb/supplier_product_invoice_form.htm",
			supplier_form => "eb/supplier_form.htm",
			supplier_tree => "eb/supplier_tree.htm",
			supplier_issue_codes_form => "eb/supplier_issue_codes_form.htm",
			supplier_list_codes => "eb/supplier_list_codes.htm",
			supplier_choose_codes => "eb/supplier_choose_codes.htm",
			activity_home => "eb/activity_home.htm",
			activity_links => "eb/activity_links.htm",
			activity_tree => "eb/activity_tree.htm",
			report_home => "eb/report_home.htm",
			yell_robot_home => "eb/yell_robot_home.htm",
			school_invoices_tree => "eb/school_invoices_tree.htm",
			download_schools_home => "eb/download_schools_home.htm",
			view_school => "eb/view_school.htm",
			schools_home => "eb/schools_home.htm",
			school_account_form => "eb/school_account_form.htm",
			school_issue_demo_cd => "eb/school_issue_demo_cd.htm",
			choose_auto_fill_school => "eb/choose_auto_fill_school.htm",
			view_invoice => "eb/view_invoice.htm",
			promotional_code_create => "eb/promotional_code_create.htm",
			set_form => "eb/set_form.htm",
			menu => "eb/menu.xml",
			window => "eb/window.htm" },

		app_skillsaudit => {
			date_wizard => "skillsaudit/date_wizard.htm",
			visitor_form => "skillsaudit/visitor_form.htm",
			visitor_tree => "skillsaudit/visitor_tree.htm",
			visitor_school_home => "skillsaudit/visitor_school_home.htm",
			visitor_audit_home => "skillsaudit/visitor_audit_home.htm",
			visitor_timeline_home => "skillsaudit/visitor_timeline_home.htm",
			visitor_group_people_home => "skillsaudit/visitor_group_people_home.htm",
			visitor_group_people_toolbar => "skillsaudit/visitor_group_people_toolbar.htm",
			visitor_group_ict_home => "skillsaudit/visitor_group_ict_home.htm",
			visitor_group_ict_toolbar => "skillsaudit/visitor_group_ict_toolbar.htm",
			visitor_group_targets_home => "skillsaudit/visitor_group_targets_home.htm",
			visitor_group_targets_toolbar => "skillsaudit/visitor_group_targets_toolbar.htm",
			visitor_group_timeline_home => "skillsaudit/visitor_group_timeline_home.htm",
			visitor_group_timeline_toolbar => "skillsaudit/visitor_group_timeline_toolbar.htm",
			visitor_group_questions_home => "skillsaudit/visitor_group_questions_home.htm",
			visitor_group_questions_toolbar => "skillsaudit/visitor_group_questions_toolbar.htm",
			ict_summary => "skillsaudit/ict_summary.htm",
			school_form => "skillsaudit/school_form.htm",
			schools_home => "skillsaudit/schools_home.htm",
			audit_template_form => "skillsaudit/audit_template_form.htm",
			window => "skillsaudit/window.htm",
			menu => "skillsaudit/menu.xml" },

		app_clubhouse => {
			menu => "clubhouse/menu.xml",
			homepage => "clubhouse/homepage.htm",
			rotating_icon_links => "clubhouse/rotating_icon_links.htm",
			icon_form => "clubhouse/rotating_icon_form.htm",
			website_course_status => "clubhouse/website_course_status.htm",
			window => "clubhouse/window.htm" },

		app_contact => {
			menu => "contact/menu.xml",
			contact_form => "contact/contact_form.htm",
			window => "contact/window.htm" },

		app_easemail => {
			easemail_home => "easemail/easemail_home.htm",
			object_list => "easemail/object_list.htm",
			remove_bounces => "easemail/remove_bounces.htm",
			unsubscribe => "easemail/unsubscribe_member.htm",
			app_home => "easemail/app_home.htm",
			email_summary => "easemail/email_summary.htm",
			confirm_send => "easemail/confirm_send.htm",
			list_tree => "easemail/list_tree.htm",
			list_form => "easemail/list_form.htm",
			list_home => "easemail/list_home.htm",
			transfer_results => "easemail/transfer_results.htm",
			transfer_members => "easemail/transfer_members.htm",
			search_members => "easemail/search_members.htm",
			upload_members => "easemail/upload_members.htm",
			upload_results => "easemail/upload_results.htm",
			download_members => "easemail/download_members.htm",
			select_multiple_lists => "easemail/select_multiple_lists.htm",
			select_list_tree => "easemail/select_list_tree.htm",
			send_email_select_lists => "easemail/send_email_select_lists.htm",
			member_form => "easemail/member_form.htm",
			email_form => "easemail/email_form.htm",
			menu => "easemail/menu.xml",
			window => "easemail/window.htm" },

		app_va => {
			menu => "va/menu.xml",
			contacts_tree => "va/contacts_tree.htm",
			jobs_tree => "va/jobs_tree.htm",
			supplier_form => "va/supplier_form.htm",
			job_details => "va/job_details.htm",
			task_form => "va/task_form.htm",
			lead_form => "va/lead_form.htm",
			project_form => "va/project_form.htm",
			project_overview => "va/project_overview.htm",
			window => "va/window.htm" },

		app_holiday => {				# The Holiday System
			menu => "holiday/menu.xml",
			login => "holiday/login.htm",
			delete_confirm => "holiday/users_delete_confirm.htm",
			sidemenu => "holiday/sidemenu.htm",
			list_users => "holiday/list_users.htm",
			user_form_wrapper => "holiday/user_form_wrapper.htm",
			holiday_form => "holiday/holiday_form.htm",
			view_day => "holiday/view_day.htm",
			view_month => "holiday/view_month.htm",
			view_year => "holiday/view_year.htm",
			pagetop => "holiday/pagetop.htm",
			add_owed_days => "holiday/add_owed_days.htm",
			delete_holiday => "holiday/delete_holiday_confirm.htm",
			export_dates => "holiday/export_dates.htm",
			window => "holiday/window.htm"
		},

		app_hiscores => {
			dltennis => "hiscores/dltennis.htm",
			tennis => "hiscores/galaxy.htm",
			archery_hard => "hiscores/afair.htm",
			archery_easy => "hiscores/asky.htm",
			balloons_hard => "hiscores/bfair.htm",
			balloons_easy => "hiscores/bsky.htm" },

		app_queryhandler => {
			menu => 'queryhandler/menu.xml',
			window => "queryhandler/window.htm",
			query_form => "queryhandler/query_form.htm",
			answer_form => "queryhandler/answer_form.htm",
			answer_form_confirm => "queryhandler/answer_form_confirm.htm",
			js_search_queries => "queryhandler/js_search_queries.htm",
			org_queries_home => "queryhandler/org_queries_home.htm",
			search_js => "queryhandler/search_js.htm",
			email_summary => "queryhandler/email_summary.htm"
		},

		app_wk1net => {
			print_tests => 'wk1net/print_tests.htm'
		},

		app_sitemanager => {
			menu => 'sitemanager/menu.xml',
			window => 'sitemanager/window.htm',
			stats_sidebar => "sitemanager/stats_sidemenu.htm",
			stats_treetitle => "sitemanager/stats_treetitle.htm",
			stats_menutitle => "sitemanager/stats_menutitle.htm",
			stats_menu => "sitemanager/stats_menu.htm",
			stats_contenttitle => "sitemanager/stats_contenttitle.htm",
			stats_content => "sitemanager/stats_content.htm",
			emails_home => "sitemanager/emails_home.htm",
			email_tree => "sitemanager/email_tree.htm",
			email_view_message => "sitemanager/view_message.htm",
			email_write_message => "sitemanager/write_message.htm",
			delete_confirm => "sitemanager/delete_confirm.htm",
			pop_account_form => "sitemanager/pop_account_form.htm",
			alias_form => "sitemanager/alias_form.htm",
			pop_alias_list => "sitemanager/pop_alias_list.htm",
			pop_account_details => "sitemanager/pop_account_details.htm",
			homepage => "sitemanager/homepage.htm",
			siteeditor_sidebar => "sitemanager/siteeditor_sidebar.htm",
			siteeditor_topbar => "sitemanager/siteeditor_topbar.htm",
			siteeditor_homepage => "sitemanager/siteeditor_homepage.htm",
			siteeditor_save_form => "sitemanager/sideeditor_save_form.htm",
			siteeditor_preview_title => "sitemanager/siteeditor_preview_title.htm",
			siteeditor_link_input => "sitemanager/siteeditor_link_input.htm"
		},

		app_rk => {
			menu => 'rk/menu.xml',
			window => 'rk/window.htm',
			homepage => 'rk/homepage.htm'
		},

		app_components => {
			menu => 'components/menu.xml',
			window => "components/window.htm",
			installation_form => "components/installation_form.htm",
			event_form => "components/event_form.htm",
			style_sheet_form => "components/style_sheet_form.htm",
			date_form => "components/date_form.htm",
			html_calendar => "components/calendar.htm",
			calendar_home => "components/calendar_home.htm",
			news_form => "components/news_form.htm",
			news_list => "components/news_list.htm",
			news_ticker_data => "components/news_ticker_data.htm",
			faq_form => "components/faq_form.htm",
			faq_list => "components/faq_list.htm",
			client_list_list => "components/clientlist_list.htm",
			client_list_form => "components/client_list_form.htm",
			overrides => {
###### This needs to be replaced with RBGC (2) After testing
				org_1 => {
					news_list => "components/rbgc/news_list.htm"
				}
			}
		},

		app_resourceshare_web => {
			resource_table_wrapper => "resourceshare_web/resource_table_wrapper.htm",
			resource_table => "resourceshare_web/default_table.htm",
			overrides => {
				org_31 => {
					resource_table_wrapper => "resourceshare_web/david_lock/resource_table_wrapper.htm",
				}
			}
		},

		app_resourceshare_clientms => {
			password_reminder => "resourceshare/password_reminder.htm",
			clientms_extra_fields => "resourceshare/clientms_extra_fields.htm",
			clients_tree => "clientms/clients_tree.htm"  },

		app_resourceshare => {
			planningsheetdetails => "resourceshare/planningsheetdetails.htm",
			bulkemail_details => "resourceshare/bulkemail_details.htm",
			jobfile_timeline => "resourceshare/jobfile_timeline.htm",
			folder_tree => "resourceshare/folder_tree.htm",
			folder_contents => "resourceshare/folder_contents.htm",
			folder_details => "resourceshare/folder_details.htm",
			discussion_details => "resourceshare/discussion_details.htm",
			client_details => "resourceshare/client_details.htm",
			jobfile_details => "resourceshare/jobfile_details.htm",
			contact_form_details => "resourceshare/contact_form_details.htm",
			comment_details => "resourceshare/comment_details.htm",
			security_details => "resourceshare/security_details.htm",
			moderation_toolbar => "resourceshare/moderation_toolbar.htm",
			moderation_home => "resourceshare/moderation_home.htm",
			moderation_resource_form => "resourceshare/moderation_resource_form.htm",
			website_folder_tree => "resourceshare/website_folder_tree.htm",
			website_options_list => "resourceshare/website_options_list.htm",
			options => "resourceshare/options.htm",
			search_events => "resourceshare/event_search_details.htm",
			privilage_tree => "resourceshare/privilage_tree.htm",
			simple_resource_details => "resourceshare/simple_resource_details.htm",
			blp_resource_details => "resourceshare/blp_resource_details.htm",
			ksera_property_details => "resourceshare/ksera_property_details.htm",
			resource_details => "resourceshare/resource_details.htm",
			event_details => "resourceshare/event_details.htm",
			recycle_bin => "resourceshare/recycle_bin.htm",
			version_list => "resourceshare/version_list.htm",
			find_resources => "resourceshare/find_resources.htm",
			download_resource => "resourceshare/download_resource.htm",
			security_error => "resourceshare/security_error.htm",
			menu => "resourceshare/menu.xml",
			window => "resourceshare/window.htm" },

		app_fileshare => {
			menu => 'fileshare/menu.xml',
			window => "fileshare/window.htm",
			privilage_tree => "fileshare/privilage_tree.htm",
			document_form => "fileshare/document_form.htm",
			document_list => "fileshare/document_list.htm" },

		app_clientms => {
			menu => 'clientms/menu.xml',
			window => "clientms/window.htm",
			clients_tree => "clientms/clients_tree.htm" },

		app_orgadmin => {				# The Org Admin System
			sidemenu => "orgadmin/sidemenu.htm",
			users_details => "orgadmin/users_details.htm" },

		app_rbgcadmin => {				# The RBGC Admin System
			menu => "rbgcadmin/menu.xml",
			scrolling_news => "rbgcadmin/scrolling_news.htm",
			general_news_list => "rbgcadmin/general_news_list.htm",
			general_news_form => "rbgcadmin/general_news_form.htm",
			social_calendar_list => "rbgcadmin/social_calendar_list.htm",
			social_calendar_form => "rbgcadmin/social_calendar_form.htm",
			society_list => "rbgcadmin/society_list.htm",
			society_form => "rbgcadmin/society_form.htm",
			window => "rbgcadmin/window.htm",
			wrapper => "rbgcadmin/wrapper.htm" },

		app_login => {					# The Login System
			list_apps => "login/list_apps.htm" },

		app_budgethub => {
			export_excel => "budgethub/export_excel.htm",
			field_schema => "budgethub/field_template.xml",
			field_detail_modal => "budgethub/field_detail_modal.htm",
			comment_modal => "budgethub/comment_modal.htm",
			field_position_modal => "budgethub/field_position_modal.htm",
			field_currency_modal => "budgethub/currency_modal.htm",
			field_currency_modal_submit => "budgethub/currency_modal_submit.htm",
			budget_toolbar => "budgethub/budget_toolbar.htm",
			menu => "budgethub/menu.xml",
			window => "budgethub/window.htm",
			blank_toolbar => "budgethub/toolbars/blank.htm",
			home => "budgethub/home_page.htm",
			file_prompt => "budgethub/file_prompt.htm",
			minimal_header => "budgethub/header_minimal.htm",
			home_sidebar => "budgethub/home_sidebar.htm",
			home_page => "budgethub/home_page.htm",
			home_toolbar => "budgethub/toolbars/home.htm",
			save_options => "budgethub/save_options.htm",
			delete_confirm => "budgethub/delete_options.htm",
			edit_budget_page => "budgethub/edit_budget_page.htm",
			budget_sidebar => "budgethub/budget_sidebar.htm",
			save_form => "budgethub/save_form.htm",
			budget_details_form => "budgethub/budget_details_form.htm" }
	}
};

my $local_dir = Webkit::Application->get_constant('template_dir');


sub get_filename
{
	my ($classname, $relative) = @_;

	my $path = $local_dir.$relative;
	
	return $path;
}

sub get_template_contents
{
	my ($classname, $key, $app, $org_id) = @_;

	my $filename = Webkit::Apache::TemplateHub->get_template_filename($key, $app, $org_id);

	if($filename=~/\w/)
	{
		my $fullpath = Webkit::Apache::TemplateHub->get_filename($filename);
		
		return Webkit::AppTools->read_file_contents($fullpath);
	}
	else
	{
		return undef;
	}
}

sub get_template_filename
{
	my ($classname, $key, $app, $org_id) = @_;

	my $ret;

	$ret = $templatedata->{apps}->{'app_'.$app}->{overrides}->{'org_'.$org_id}->{$key};

	if($ret)
	{
		return Webkit::Apache::TemplateHub->get_template_ref_filename($ret);
	}

	$ret = $templatedata->{apps}->{'app_'.$app}->{$key};

	if($ret)
	{
		return Webkit::Apache::TemplateHub->get_template_ref_filename($ret);
	}

	$ret = $templatedata->{app_defaults}->{overrides}->{'org_'.$org_id}->{$key};

	if($ret)
	{
		return Webkit::Apache::TemplateHub->get_template_ref_filename($ret);
	}

	$ret = $templatedata->{app_defaults}->{$key};

	if($ret)
	{
		return Webkit::Apache::TemplateHub->get_template_ref_filename($ret);
	}
}

#### Some template filenames are refs containing default and mac versions - this returns the correct version
sub get_template_ref_filename
{
	my ($classname, $ref) = @_;

	if(!ref($ref))
	{
		return $ref;
	}

	my $browser = Webkit::Browser->new;

	if($browser->is_mac)
	{
		return $ref->{mac};
	}
	else
	{
		return $ref->{default};
	}
}

sub get_org_logo_details
{
	my ($classname, $org) = @_;

	if($logos->{$org->get_id})
	{
		return $logos->{$org->get_id};
	}

	if($logos->{$org->get_value('parent_org_id')})
	{
		return $logos->{$org->get_value('parent_org_id')};
	}

	return $logos->{1};
}


########################################################
########################################################
########################################################
########################################################
########################################################
########################################################
########################################################
########################################################
########################################################
### HANDLER METHODS
########################################################
########################################################
########################################################
########################################################
########################################################
########################################################
########################################################
########################################################
########################################################

sub wkhtml_handler
{
	my ($r) = @_;

	my $request = Apache2::Request->new($r);

	my $params;

	foreach my $key ($request->param)
	{
		$params->{$key} = $request->param($key);
	}

	my $uri = $r->uri;

	if($uri=~/^\/wkhtml\/(\w+)\//)
	{
		my $method = $1;

		$method .= '_handler';

		return &$method($r, $params);
	}
	else
	{
		return NOT_FOUND;
	}
}



sub iframe_title_frame_handler
{
	my ($r, $params) = @_;

	my $href = Webkit::Application->class_href($params->{session_id}, $params->{appname});

	my $frameset = Webkit::Apache::TemplateHub->iframe_title_frame_html({
		params => $params,
		href => $href });

	$r->content_type('text/html');
	$r->set_content_length(length($frameset));
	$r->send_http_header;

	$r->print($frameset);

	return $Apache2::Const::OK;
}

sub iframe_title_frame_html
{
	my ($classname, $props) = @_;

	my $params = $props->{params};

	my $title = $params->{title};
	my $method = $params->{frame_method};
	my $session_id = $params->{session_id};

	delete($params->{title});
	delete($params->{frame_method});
	delete($params->{session_id});

	my $query;

	my @pairs;

	foreach my $key (keys %{$params})
	{
		push(@pairs, $key.'='.$params->{$key});
	}

	$query = join('&', @pairs);

	my $href = $props->{href};

	my $html=<<"+++";
<HTML>
<HEAD>
<script>
var normalTitleHeight = 21;
var normalTitleUrl = 'http://testingtool.net/wkhtml/iframe_title/?title=Data';
var currentTitleUrl = normalTitleUrl;

function setTitleUrl(newUrl)
{
	if(newUrl!=currentTitleUrl)
	{
		currentTitleUrl = newUrl;
		document.getElementById('title').src = newUrl;
	}
}

function resetTitleUrl()
{
	document.getElementById('title').src= normalTitleUrl;
}

function setTitleHeight(newHeight)
{
	var frameset = document.getElementById("outer");
	frameset.rows = newHeight + ',*';
}

function resetTitleHeight()
{
	var frameset = document.getElementById("outer");
	frameset.rows = normalTitleHeight + ',*';
}
</script>
<META HTTP-EQUIV="MSThemeCompatible" Content="no">
</HEAD>
<frameset id="outer" rows="21,*" border="0" style="border-right:1px #808080 solid; border-bottom:1px #808080 solid; border-top:1px #FFFFFF solid; border-left:1px #FFFFFF solid;">
<frame id="title" src="/wkhtml/iframe_title/?title=$title" scrolling="no" name="title" frameborder="0">
<frame id="content" src="$href&method=$method&$query" scrolling="auto" name="content" frameborder="0">
</frameset>
</HTML>
+++

	return $html;
}

sub iframe_single_frame_handler
{
	my ($r, $params) = @_;

	my $href = Webkit::Application->class_href($params->{session_id}, $params->{appname});

	my $frameset = Webkit::Apache::TemplateHub->iframe_single_frame_html({
		params => $params,
		href => $href });

	$r->content_type('text/html');
	$r->set_content_length(length($frameset));
	$r->send_http_header;

	$r->print($frameset);

	return $Apache2::Const::OK;
}

sub iframe_single_frame_html
{
	my ($classname, $props) = @_;

	my $params = $props->{params};

	my $title = $params->{title};
	my $method = $params->{frame_method};
	my $session_id = $params->{session_id};

	delete($params->{title});
	delete($params->{frame_method});
	delete($params->{session_id});

	my $query;

	my @pairs;

	foreach my $key (keys %{$params})
	{
		push(@pairs, $key.'='.$params->{$key});
	}

	$query = join('&', @pairs);

	my $href = $props->{href};

	my $html=<<"+++";
<HTML>
<HEAD>
<script>
var normalTitleHeight = 21;
var normalTitleUrl = 'http://testingtool.net/wkhtml/iframe_title/?title=Data';
var currentTitleUrl = normalTitleUrl;

function setTitleUrl(newUrl)
{
	if(newUrl!=currentTitleUrl)
	{
		currentTitleUrl = newUrl;
		document.getElementById('title').src = newUrl;
	}
}

function resetTitleUrl()
{
	document.getElementById('title').src= normalTitleUrl;
}

function setTitleHeight(newHeight)
{
	document.getElementById('titleTd').height = newHeight;
	document.getElementById('title').height = newHeight;
}

function resetTitleHeight()
{
	document.getElementById('titleTd').height = normalTitleHeight;
	document.getElementById('title').height = normalTitleHeight;
}
</script>
<META HTTP-EQUIV="MSThemeCompatible" Content="no">
</HEAD>
<BODY style="margin:0px;">
<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0" WIDTH="100%" HEIGHT="100%" STYLE="border-left:#808080 1px solid; border-right:#FFFFFF 1px solid; border-top:#808080 1px solid; border-bottom:#FFFFFF 1px solid;"><TR><TD WIDTH="100%" HEIGHT="100%">
<TABLE WIDTH="100%" BORDER="0" CELLPADDING="0" CELLSPACING="0" HEIGHT="100%" STYLE="border-right:1px #808080 solid; border-bottom:1px #808080 solid; border-top:1px #FFFFFF solid; border-left:1px #FFFFFF solid;">
<TR><TD HEIGHT="21" id="titleTd"><IFRAME id="title" SRC="/wkhtml/iframe_title/?title=$title" WIDTH="100%" HEIGHT="21" NAME="title" SCROLLING="NO" FRAMEBORDER="0"></IFRAME></TD></TR>
<TR><TD HEIGHT="100%" id="contentTd"><IFRAME id="content" SRC="/apps/nctest.app?session_id=$session_id&method=$method" WIDTH="100%" HEIGHT="100%" NAME="content" SCROLLING="AUTO" FRAMEBORDER="0"></IFRAME></TD></TR>
</TABLE>
</TD></TR></TABLE>
</BODY>
</HTML>
+++

	return $html;
}

sub iframe_title_handler
{
	my ($r, $params) = @_;

	my $text = Webkit::Apache::TemplateHub->iframe_title_html({
		title => $params->{title} });

	$r->content_type('text/html');
	$r->set_content_length(length($text));
	$r->send_http_header;

	$r->print($text);

	return $Apache2::Const::OK;
}

sub iframe_title_html
{
	my ($classname, $props) = @_;

	my $title = $props->{title};

	my $html=<<"+++";
<HTML>
<HEAD><TITLE></TITLE>
<script>
	function set_title(text)
	{
		document.getElementById('title').innerText = text;
	}
</script>
<STYLE TYPE="text/css">
body {background:#D4D0C8; border:0px; margin:0px;}</STYLE>
  </HEAD>
  <META HTTP-EQUIV="MSThemeCompatible" Content="no">
 <BODY LEFTMARGIN="0" TOPMARGIN="0" MARGINWIDTH="0" MARGINHEIGHT="0">
 <TABLE WIDTH="100%" BORDER="0" CELLPADDING="2" CELLSPACING="0" STYLE="border-bottom:1px #808080 solid;" HEIGHT="100%">
		<TR>
		  <TD WIDTH="100%" HEIGHT="100%" STYLE="font-family:tahoma,verdana; font-size:11px; color:#000000;">&nbsp;<span id="title">$title</span></TD>
		</TR>
</TABLE></BODY>
</HTML>
+++

	return $html;
}

sub vertical_frameset_handler
{
	my ($r, $params) = @_;

	my @details_keys = qw(appname left_title left_method right_title right_method width right_frame_method left_frame_method);

	my $props = {
		href => Webkit::Application->class_href($params->{session_id}),
		session_id => $params->{session_id} };

	my $details_props = $frameset_attributes->{$params->{details_key}};

	foreach my $key (@details_keys)
	{
		if($details_props)
		{
			$props->{$key} = $details_props->{$key};
		}
		else
		{
			$props->{$key} = $params->{$key};
		}
	}

	my $frameset = Webkit::Apache::TemplateHub->vertical_frameset_html($props);

	$r->content_type('text/html');
	$r->set_content_length(length($frameset));
	$r->send_http_header;

	$r->print($frameset);

	return $Apache2::Const::OK;
}

sub vertical_frameset_html
{
	my ($classname, $props) = @_;

	my $left_title = $props->{left_title};
	my $left_method = $props->{left_method};
	my $left_frame_method = $props->{left_frame_method};

	my $right_title = $props->{right_title};
	my $right_method = $props->{right_method};
	my $right_frame_method = $props->{right_frame_method};

	my $appname = $props->{appname};

	my $width = $props->{width};

	if(!$width)
	{
		$width = 200;
	}

	my $href = $props->{href};
	my $session_id = $props->{session_id};

	my $right_src = "/wkhtml/vertical_frameset_col/?method=$right_method&title=$right_title&session_id=$session_id&appname=$appname";

	if($right_frame_method=~/\w/)
	{
		$right_src = "/apps/$appname.app?session_id=$session_id&method=$right_frame_method";
	}

	my $left_src = "/wkhtml/vertical_frameset_col/?method=$left_method&title=$left_title&session_id=$session_id&appname=$appname";

	if($left_frame_method=~/\w/)
	{
		$left_src = "/apps/$appname.app?session_id=$session_id&method=$left_frame_method";
	}

	my $html=<<"+++";
<HTML>
<META HTTP-EQUIV="MSThemeCompatible" Content="no">
  <FRAMESET COLS="$width,*" ID="vertical_frameset" FRAMEBORDER="YES" BORDER="5" bordercolor="#d4d0c8">
  <FRAME NAME="sidebar" SRC="$left_src" MARGINWIDTH="5" MARGINHEIGHT="5" STYLE="border-left:#808080 1px solid; border-right:#FFFFFF 1px solid; border-top:#808080 1px solid; border-bottom:#FFFFFF 1px solid;" SCROLLING="NO" FRAMEBORDER="NO">
  <FRAME NAME="page" SRC="$right_src" FRAMEBORDER="NO" MARGINWIDTH="5" MARGINHEIGHT="5" STYLE="border-left:#808080 1px solid; border-right:#FFFFFF 1px solid; border-top:#808080 1px solid; border-bottom:#FFFFFF 1px solid;" SCROLLING="NO"> </FRAMESET>
</HTML>
+++

	return $html;
}

sub vertical_frameset_col_handler
{
	my ($r, $params) = @_;

	my $href.="/apps/$params->{appname}.app";

	$href.='?session_id='.$params->{session_id};

	my $frameset = Webkit::Apache::TemplateHub->vertical_frameset_col_html({
		title => $params->{title},
		method => $params->{method},
		href => $href });

	$r->content_type('text/html');
	$r->set_content_length(length($frameset));
	$r->send_http_header;

	$r->print($frameset);

	return $Apache2::Const::OK;
}

sub vertical_frameset_col_html
{
	my ($classname, $props) = @_;

	my $href = $props->{href};
	my $title = $props->{title};
	my $method = $props->{method};

	my $html=<<"+++";
<HTML>
<HEAD>
<script>
var normalTitleHeight = 21;
var normalTitleUrl = '/wkhtml/iframe_title/?title=Data';
var currentTitleUrl = normalTitleUrl;

function setTitleUrl(newUrl)
{
	if(newUrl!=currentTitleUrl)
	{
		currentTitleUrl = newUrl;
		document.getElementById('title').src = newUrl;
	}
}

function resetTitleUrl()
{
	document.getElementById('title').src= normalTitleUrl;
}

function setTitleHeight(newHeight)
{
	var frameset = document.getElementById("outer");
	frameset.rows = newHeight + ',*';
}

function resetTitleHeight()
{
	var frameset = document.getElementById("outer");
	frameset.rows = normalTitleHeight + ',*';
}
</script>
<META HTTP-EQUIV="MSThemeCompatible" Content="no">
</HEAD>
<frameset id="outer" rows="21,*" border="0" style="border-right:1px #808080 solid; border-bottom:1px #808080 solid; border-top:1px #FFFFFF solid; border-left:1px #FFFFFF solid;">
<frame id="title" src="/wkhtml/iframe_title/?title=$title" scrolling="no" name="title" frameborder="0">
<frame id="content" src="$href&method=$method" scrolling="auto" name="content" frameborder="0">
</frameset>
</HTML>
</HTML>
+++

	return $html;
}

sub modal_frameset_handler
{
	my ($r, $params) = @_;

	my $href.="/apps/$params->{appname}.app";

	my $title = $params->{title};

	delete($params->{appname});
	delete($params->{title});

	my $frameset = Webkit::Apache::TemplateHub->modal_frameset_html({
		params => $params,
		title => $title,
		href => $href });

	$r->content_type('text/html');
	$r->set_content_length(length($frameset));
	$r->send_http_header;

	$r->print($frameset);

	return $Apache2::Const::OK;
}

sub modal_frameset_html
{
	my ($classname, $props) = @_;

	my $href = $props->{href};

	my $pairs;

	foreach my $key (keys %{$props->{params}})
	{
		push(@$pairs, $key.'='.$props->{params}->{$key});
	}

	$href .= '?'.join('&', @$pairs);

	my $title = 'Webkit';

	if($props->{title}=~/\w/)
	{
		$title = $props->{title};
	}

	my $html=<<"+++";
<html>
<head>
	<title>$title &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;</title>
<META HTTP-EQUIV="MSThemeCompatible" Content="no">
</head>
<frameset border=0 rows="100%, 0">
<frame src="$href" scrolling="auto">
</frameset>
</html>
+++

	return $html;
}

sub mac_file_handler
{
	my $r = shift;

	my $uri = $r->uri;

#	if(!$mac_filepaths->{$uri})
#	{
#		return;
#	}

	my $browser = Webkit::Browser->new;

#	if($browser->is_mac)
#	{
		$uri=~ s/\/(\w+)\.(\w+)$/\/$1_mac\.$2/;

		$r->uri($uri);
#	}

	return $Apache2::Const::OK;
}

1;

/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

import "core-js/stable";
import "regenerator-runtime/runtime";

import ahoy from "ahoy.js";
window.ahoy = ahoy;

import "./egotter";
import "./cache";
import "./mustache_util";
import "./modal_dialog";
import "./toast_message";
import "./welcome";
import "./async_loader";
import "./home";
import "./follow_and_unfollow";
import "./search_modal";
import "./order_details_modal";
import "./end_trial_modal";
import "./reset_cache_modal";
import "./reset_egotter_modal";
import "./sort_and_filter";
import "./word_cloud";
import "./tweet_cluster";
import "./audience_insight";
import "./usage_stat";
import "./archive_data_uploader";
import "./delete_tweets_modal";
import "./delete_favorites_modal";
import "./result_pages";
import "./settings";
import "./orders";
import "./timelines";
import "./waiting";
import "./bg_update";
import "./ad_block_detector";
import "./cognite_mode_detector";
import "./heart";
import "./announcements";
import "./features";
import "./functions";
import "./profile_loader";

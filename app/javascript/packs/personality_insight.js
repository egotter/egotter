var PersonalityTraitInfo = require('personality-trait-info');
var PersonalityTextSummaries = require('personality-text-summary');
var PersonalityConsumptionPreferences = require('personality-consumption-preferences');

var traitInfo = new PersonalityTraitInfo({locale: 'ja', version: 'v3'});
var v3JapaneseTextSummaries = new PersonalityTextSummaries({locale: 'ja', version: 'v3'});
var consumptionPreferences = new PersonalityConsumptionPreferences({locale: 'ja', version: 'v3'});

class PersonalityInsight {
  constructor() {
    this.i18n = new I18n();
  }

  drawTraits(selector, traits) {
    var i18n = this.i18n;

    var categories = traits.map(function (trait) {
      return i18n.t(trait['trait_id']);
    });

    var scores = traits.map(function (trait) {
      return trait['raw_score'] * 100;
    });

    this.drawPolarChart(selector, categories, scores);
  }

  drawFacets(selector, facets) {
    var i18n = this.i18n;

    var categories = facets.map(function (facet) {
      return i18n.t(facet['trait_id']);
    });

    var scores = facets.map(function (facet) {
      return facet['raw_score'] * 100;
    });

    this.drawPolarChart(selector, categories, scores);
  }

  drawPolarChart(selector, categories, scores) {
    Highcharts.chart(selector, {
      chart: {
        polar: true,
        type: 'line'
      },
      title: {
        text: null
      },
      xAxis: {
        categories: categories,
        tickmarkPlacement: 'on',
        lineWidth: 0
      },
      yAxis: {
        gridLineInterpolation: 'polygon',
        min: 0,
        max: 100
      },
      legend: {enabled: false},
      series: [{
        data: scores,
        pointPlacement: 'on'
      }],
      credits: {enabled: false}
    });
  }

  getSummary(data) {
    var personalityProfile = new v3JapaneseTextSummaries.PersonalityProfile(data);
    return v3JapaneseTextSummaries.assemble(personalityProfile).map(function (paragraph) {
      return paragraph.join(' ').replace(/\./g, '。').replace(/: /g, '：');
    });
  }

  getConsumptionPreferences(data) {
    return getConsumptionPreferences(data);
  }
}

window.PersonalityInsight = PersonalityInsight;

class I18n {
  t(key) {
    return traitInfo.name(key);
  }
}

window.PersonalityInsight.I18n = I18n;

var jaSortLikely = [
  'consumption_preferences_movie_musical',
  'consumption_preferences_automobile_ownership_cost',
  'consumption_preferences_music_playing',
  'consumption_preferences_movie_historical',
  'consumption_preferences_read_motive_enjoyment',
  'consumption_preferences_volunteer',
  'consumption_preferences_movie_science_fiction',
  'consumption_preferences_books_non_fiction',
  'consumption_preferences_read_frequency',
  'consumption_preferences_volunteering_time',
  'consumption_preferences_concerned_environment',
  'consumption_preferences_books_autobiographies',
  'consumption_preferences_volunteer_learning',
  'consumption_preferences_music_classical',
  'consumption_preferences_clothes_comfort',
  'consumption_preferences_music_rock',
  'consumption_preferences_movie_documentary',
  'consumption_preferences_movie_adventure',
  'consumption_preferences_movie_action',
  'consumption_preferences_read_motive_relaxation',
  'consumption_preferences_movie_war',
  'consumption_preferences_clothes_quality',
  'consumption_preferences_music_live_event',
  'consumption_preferences_influence_family_members',
  'consumption_preferences_read_motive_information',
  'consumption_preferences_influence_utility',
  'consumption_preferences_music_latin',
  'consumption_preferences_automobile_safety',
  'consumption_preferences_movie_drama',
  'consumption_preferences_books_entertainment_magazines',
  'consumption_preferences_movie_horror',
  'consumption_preferences_outdoor',
  'consumption_preferences_automobile_resale_value',
  'consumption_preferences_influence_online_ads',
  'consumption_preferences_books_financial_investing',
  'consumption_preferences_start_business',
  'consumption_preferences_credit_card_payment',
  'consumption_preferences_movie_romance',
  'consumption_preferences_gym_membership',
  'consumption_preferences_fast_food_frequency',
  'consumption_preferences_music_country',
  'consumption_preferences_adventurous_sports',
  'consumption_preferences_read_motive_mandatory',
  'consumption_preferences_influence_brand_name',
  'consumption_preferences_spur_of_moment',
  'consumption_preferences_influence_social_media',
  'consumption_preferences_eat_out',
  'consumption_preferences_music_r_b',
  'consumption_preferences_clothes_style',
  'consumption_preferences_music_rap',
  'consumption_preferences_music_hip_hop'
];

var jaSortUnlikely = [
  'consumption_preferences_influence_family_members',
  'consumption_preferences_read_motive_information',
  'consumption_preferences_influence_utility',
  'consumption_preferences_music_latin',
  'consumption_preferences_automobile_safety',
  'consumption_preferences_movie_drama',
  'consumption_preferences_books_entertainment_magazines',
  'consumption_preferences_movie_horror',
  'consumption_preferences_outdoor',
  'consumption_preferences_automobile_resale_value',
  'consumption_preferences_influence_online_ads',
  'consumption_preferences_books_financial_investing',
  'consumption_preferences_start_business',
  'consumption_preferences_credit_card_payment',
  'consumption_preferences_movie_romance',
  'consumption_preferences_gym_membership',
  'consumption_preferences_fast_food_frequency',
  'consumption_preferences_music_country',
  'consumption_preferences_adventurous_sports',
  'consumption_preferences_read_motive_mandatory',
  'consumption_preferences_influence_brand_name',
  'consumption_preferences_spur_of_moment',
  'consumption_preferences_influence_social_media',
  'consumption_preferences_eat_out',
  'consumption_preferences_music_r_b',
  'consumption_preferences_clothes_style',
  'consumption_preferences_music_rap',
  'consumption_preferences_music_hip_hop',
  'consumption_preferences_movie_musical',
  'consumption_preferences_automobile_ownership_cost',
  'consumption_preferences_music_playing',
  'consumption_preferences_movie_historical',
  'consumption_preferences_read_motive_enjoyment',
  'consumption_preferences_volunteer',
  'consumption_preferences_movie_science_fiction',
  'consumption_preferences_books_non_fiction',
  'consumption_preferences_read_frequency',
  'consumption_preferences_volunteering_time',
  'consumption_preferences_concerned_environment',
  'consumption_preferences_books_autobiographies',
  'consumption_preferences_volunteer_learning',
  'consumption_preferences_music_classical',
  'consumption_preferences_clothes_comfort',
  'consumption_preferences_music_rock',
  'consumption_preferences_movie_documentary',
  'consumption_preferences_movie_adventure',
  'consumption_preferences_movie_action',
  'consumption_preferences_read_motive_relaxation',
  'consumption_preferences_movie_war',
  'consumption_preferences_clothes_quality',
  'consumption_preferences_music_live_event'
];

var consumptionPrefMusic = new Set([
  'consumption_preferences_music_rap',
  'consumption_preferences_music_country',
  'consumption_preferences_music_r_b',
  'consumption_preferences_music_hip_hop',
  'consumption_preferences_music_live_event',
  'consumption_preferences_music_playing',
  'consumption_preferences_music_latin',
  'consumption_preferences_music_rock',
  'consumption_preferences_music_classical'
]);

var consumptionPrefMovie = new Set([
  'consumption_preferences_movie_romance',
  'consumption_preferences_movie_adventure',
  'consumption_preferences_movie_horror',
  'consumption_preferences_movie_musical',
  'consumption_preferences_movie_historical',
  'consumption_preferences_movie_science_fiction',
  'consumption_preferences_movie_war',
  'consumption_preferences_movie_drama',
  'consumption_preferences_movie_action',
  'consumption_preferences_movie_documentary'
]);

function cpIdMapping(consumption_preference_id) {
  return consumptionPreferences.description(consumption_preference_id);
}

function cpIdSortingLikely(cpid) {
  return jaSortLikely.indexOf(cpid);
}

function cpIdSortingUnlikely(cpid) {
  return jaSortUnlikely.indexOf(cpid);
}

function addIfAllowedReducer(accumulator, toadd) {
  if (consumptionPrefMusic.has(toadd.cpid)) {
    if (accumulator.reduce(function (k, v) {
      return consumptionPrefMusic.has(v.cpid)
          ? k + 1
          : k;
    }, 0) < 1) {
      accumulator.push(toadd);
    }
  } else if (consumptionPrefMovie.has(toadd.cpid)) {

    if (accumulator.reduce(function (k, v) {
      return consumptionPrefMovie.has(v.cpid)
          ? k + 1
          : k;
    }, 0) < 1) {
      accumulator.push(toadd);
    }
  } else {
    accumulator.push(toadd);
  }
  return accumulator;
}

function sortIdxComparator(x, y) {

  var a = x.idx;
  var b = y.idx;

  if (a < b) {
    return -1;
  }

  if (a > b) {
    return 1;
  }

  if (a === b) {
    return 0;
  }
}

function getConsumptionPreferences(cps) {
  var likelycps = cps.reduce(function (k, v) {
    v.consumption_preferences.map(function (child_item) {
      if (child_item.score === 1) {
        k.push({
          name: cpIdMapping(child_item.consumption_preference_id),
          idx: cpIdSortingLikely(child_item.consumption_preference_id),
          cpid: child_item.consumption_preference_id
        });
      }
    });
    return k;
  }, []);

  var unlikelycps = cps.reduce(function (k, v) {
    v.consumption_preferences.map(function (child_item) {
      if (child_item.score === 0) {
        k.push({
          name: cpIdMapping(child_item.consumption_preference_id),
          idx: cpIdSortingUnlikely(child_item.consumption_preference_id),
          cpid: child_item.consumption_preference_id
        });
      }
    });
    return k;
  }, []);

  likelycps = likelycps.sort(sortIdxComparator).reduce(addIfAllowedReducer, []).slice(0, 3);
  unlikelycps = unlikelycps.sort(sortIdxComparator).reduce(addIfAllowedReducer, []).slice(0, 3);

  return [likelycps, unlikelycps];
}

class WordCloud {
  // data = [
  //   {word: 'w1', count: 1},
  //   {word: 'w2', count: 2}
  // ]
  constructor(selector, data, width, height, smartphone) {
    if (data.length >= 300) {
      data.sort(function (x, y) {
        return d3.descending(x.count, y.count);
      });
      data = data.splice(0, 300);
    }

    var random = d3.random.irwinHall(2);

    function rotateWord() {
      return Math.round(1 - random()) * 90;
    }

    var countMax = d3.max(data, function (d) {
      return d.count;
    });

    var rangeMax;
    if (smartphone) {
      rangeMax = data.length > 500 ? 100 : 50;
    } else {
      rangeMax = data.length > 500 ? 1000 : 100;
    }
    console.log('rangeMax', rangeMax);

    var sizeScale = d3.scale.linear().domain([0, countMax]).range([10, rangeMax]);
    var colorScale = d3.scale.category20();

    var words = data.map(function (d) {
      return {
        text: d.word,
        size: sizeScale(d.count)
      };
    });

    function draw(words) {
      d3.select(selector).append("svg")
          .attr("width", width)
          .attr("height", height)
          .append("g")
          .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")")
          .selectAll("text")
          .data(words)
          .enter()
          .append("text")
          .style({
            "font-family": "Impact",
            "font-size": function (d) {
              return d.size + "px";
            },
            "fill": function (d, i) {
              return colorScale(i);
            }
          })
          .attr({
            "text-anchor": "middle",
            "transform": function (d) {
              return "translate(" + [d.x, d.y] + ")rotate(" + d.rotate + ")";
            }
          })
          .attr("text-anchor", "middle")
          .on("click", function (d) {
            window.open('https://twitter.com/search?q=' + encodeURIComponent(d.text), "_blank");
          })
          .text(function (d) {
            return d.text;
          });
    }

    d3.layout.cloud().size([width, height])
        .words(words)
        .rotate(rotateWord)
        .font("Impact")
        .fontSize(function (d) {
          return d.size;
        })
        .on("end", draw)
        .start();
  }
}

window.WordCloud = WordCloud;

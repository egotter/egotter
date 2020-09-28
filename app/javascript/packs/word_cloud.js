class WordCloud {
  // data = [
  //   {word: 'w1', count: 1},
  //   {word: 'w2', count: 2}
  // ]
  constructor(selector, data, width, height, smartphone) {
    this.selector = selector;
    this.width = width;
    this.height = height;
    this.watermarkOffset = 30;

    if (data.length >= 300) {
      data.sort(function (x, y) {
        return d3.descending(x.count, y.count);
      });
      data = data.splice(0, 300);
    }
    this.data = data;

    var rangeMax;
    if (smartphone) {
      rangeMax = data.length > 500 ? 100 : 50;
    } else {
      rangeMax = data.length > 500 ? 1000 : 100;
    }
    this.rangeMax = rangeMax;
  }

  draw() {
    var selector = this.selector;
    var width = this.width;
    var height = this.height;
    var watermarkOffset = this.watermarkOffset;
    var data = this.data;
    var random = d3.random.irwinHall(2);

    function rotateWord() {
      return Math.round(1 - random()) * 90;
    }

    var countMax = d3.max(data, function (d) {
      return d.count;
    });

    var sizeScale = d3.scale.linear().domain([0, countMax]).range([10, this.rangeMax]);
    var colorScale = d3.scale.category20();

    var words = data.map(function (d) {
      return {
        text: d.word,
        size: sizeScale(d.count)
      };
    });

    function draw(words) {
      d3.select('#' + selector).append("svg")
          .attr("id", selector + '-svg')
          .attr("width", width)
          .attr("height", height - watermarkOffset)
          .append("g")
          .attr("transform", "translate(" + width / 2 + "," + (height - watermarkOffset) / 2 + ")")
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

    d3.layout.cloud().size([width, height - watermarkOffset])
        .words(words)
        .rotate(rotateWord)
        .font("Impact")
        .fontSize(function (d) {
          return d.size;
        })
        .on("end", draw)
        .start();

    this.drawWatermark();
  }

  drawWatermark() {
    var svg = $('#' + this.selector).find('svg');
    svg.attr('height', parseInt(svg.attr('height')) + this.watermarkOffset);
    new Watermark(svg.attr('id'), svg.attr('width'), svg.attr('height')).draw();
  }
}

window.WordCloud = WordCloud;

class Watermark {
  constructor(id, x, y) {
    this.elem = d3.select('#' + id);
    this.x = parseInt(x);
    this.y = parseInt(y) - 7;
    this.name = '#ワードクラウド';
    this.domain = 'egotter.com';
    this.nameOffset = 14;
  }

  draw() {
    this.drawName();
    this.drawDomain();
  }

  drawName() {
    this.elem.append("svg:text")
        .attr("x", this.x)
        .attr("y", this.y - this.nameOffset)
        .attr("text-anchor", 'end')
        .attr("font-size", 10)
        .attr("style", 'fill: #EA2184;')
        .text(this.name);
  }

  drawDomain() {
    this.elem.append("svg:text")
        .attr("x", this.x)
        .attr("y", this.y)
        .attr("text-anchor", 'end')
        .attr("font-size", 12)
        .attr("style", 'fill: #EA2184;')
        .text(this.domain);
  }
}

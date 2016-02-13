// not using
function draw_friends_map(selector, nodes, edges, width, height) {
  var fill = d3.scale.category20();

  var layout = d3.layout.force()
      .charge(-30)
      .linkDistance(150)
      .nodes(nodes)
      .links(edges)
      .size([width, height]);

  var force = layout.start();

  var svg = d3.select(selector).append("svg")
      .attr("width", layout.size()[0])
      .attr("height", layout.size()[1]);

  var link = svg.selectAll(".link")
      .data(edges)
      .enter().append("line")
      .attr("class", "link")
      .style("stroke-width", function (d) {
        if (Math.sqrt(d.weight) < 5) {
          return Math.sqrt(d.weight);
        } else {
          return 5;
        }
      })
      .style("stroke", "#777777")
      .style("stroke-opacity", 0.25);

  var node = svg.selectAll(".node")
      .data(nodes)
      .enter().append("circle")
      .attr("class", "node")
      .attr("r", function (d) {
        return 2 + parseFloat(d.value);
      })
      .style("fill", function (d) {
        return fill(d.group - 1);
      })
      .style("stroke", "#ffffff")
      .style("stroke-width", 1)
      .call(force.drag);

  var txt = svg.selectAll(".txt")
      .data(nodes)
      .enter().append("text")
      .attr("class", "txt")
      .attr("text-anchor", "middle")
      .style("font-size", "12px")
      .text(function (d) {
        return d.name;
      })
      .call(force.drag);

  force.on('tick', function () {
    link.attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; });

    node.attr("cx", function (d) { return d.x; })
        .attr("cy", function (d) { return d.y; });

    txt.attr("x", function (d) { return d.x; })
        .attr("y", function (d) { return d.y; });
  });
}

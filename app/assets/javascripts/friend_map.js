// https://github.com/d3/d3-force
// http://bl.ocks.org/mbostock/4062045
// http://lisia.hatenadiary.jp/entry/2014/07/11/225904
function draw_friend_map(selector, nodes, links, width, height) {
  var svg = d3.select(selector).append("svg")
      .attr("width", width)
      .attr("height", height);

  var color = function (i) { return '#999' };

  var simulation = d3.forceSimulation()
      .force("link", d3.forceLink().id(function(d) { return d.id; }))
      .force("charge", d3.forceManyBody().strength(-1000))
      .force("xAxis", d3.forceX().strength(0.01))
      .force("yAxis",d3.forceY().strength(0.5))
      .force("center", d3.forceCenter(width / 2, height / 2));

  var link = svg.append("g")
      .attr("class", "links")
      .selectAll("line")
      .data(links)
      .enter().append("line")
      .attr("stroke-width", function(d) { return Math.sqrt(d.value); })
      .attr("stroke", function(d) { return color(d.group); });

  var node = svg.append("g")
      .attr("class", "nodes")
      .selectAll("image")
      .data(nodes)
      .enter().append("image")
      .attr("xlink:href", function (d) { return d.url; })
      .attr("width", 30)
      .attr("height", 30)
      .call(d3.drag()
          .on("start", dragstarted)
          .on("drag", dragged)
          .on("end", dragended));

  node.append("title")
      .text(function(d) { return d.id; });

  simulation
      .nodes(nodes)
      .on("tick", ticked);

  simulation.force("link")
      .links(links);

  function ticked() {
    link
        .attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; });

    node
        .attr("x", function(d) { return d.x; })
        .attr("y", function(d) { return d.y; });
  }

  function dragstarted(d) {
    if (!d3.event.active) simulation.alphaTarget(0.3).restart();
    d.fx = d.x;
    d.fy = d.y;
  }

  function dragged(d) {
    d.fx = d3.event.x;
    d.fy = d3.event.y;
  }

  function dragended(d) {
    if (!d3.event.active) simulation.alphaTarget(0);
    d.fx = null;
    d.fy = null;
  }
}
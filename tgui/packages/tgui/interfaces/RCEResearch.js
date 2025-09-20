import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Stack, ProgressBar, Flex, Tabs, LabeledList, Tooltip } from '../components';
import { Window } from '../layouts';
import { Component, createRef } from 'inferno';

// Constants for tree visualization
const NODE_WIDTH = 120;
const NODE_HEIGHT = 80;
const TIER_SPACING = 200;
const NODE_SPACING = 150;

// Color scheme for nodes
const NODE_COLORS = {
  locked: '#444444',
  available: '#4169E1',
  in_progress: '#FFA500',
  completed: '#32CD32',
};

// Position nodes by tier
const TIER_POSITIONS = {
  1: { x: 100, y: 250 },
  2: { x: 350, y: 250 },
  3: { x: 600, y: 250 },
};

class ResearchTree extends Component {
  constructor(props) {
    super(props);
    this.state = {
      offsetX: 0,
      offsetY: 0,
      isDragging: false,
      dragStartX: 0,
      dragStartY: 0,
      selectedNode: null,
      zoom: 1,
    };
    this.canvasRef = createRef();
    // Bind methods
    this.handleMouseDown = this.handleMouseDown.bind(this);
    this.handleMouseMove = this.handleMouseMove.bind(this);
    this.handleMouseUp = this.handleMouseUp.bind(this);
    this.handleWheel = this.handleWheel.bind(this);
    this.getNodePosition = this.getNodePosition.bind(this);
    this.drawTree = this.drawTree.bind(this);
    this.handleCanvasClick = this.handleCanvasClick.bind(this);
  }

  componentDidMount() {
    this.drawTree();
  }

  componentDidUpdate() {
    this.drawTree();
  }

  handleMouseDown(e) {
    this.setState({
      isDragging: true,
      dragStartX: e.clientX - this.state.offsetX,
      dragStartY: e.clientY - this.state.offsetY,
    });
  }

  handleMouseMove(e) {
    if (this.state.isDragging) {
      this.setState({
        offsetX: e.clientX - this.state.dragStartX,
        offsetY: e.clientY - this.state.dragStartY,
      });
    }
  }

  handleMouseUp() {
    this.setState({ isDragging: false });
  }

  handleWheel(e) {
    e.preventDefault();
    const delta = e.deltaY > 0 ? 0.9 : 1.1;
    const newZoom = Math.max(0.5, Math.min(2, this.state.zoom * delta));
    this.setState({ zoom: newZoom });
  }

  getNodePosition(node, index) {
    const tierBase = TIER_POSITIONS[node.tier] || { x: 100, y: 250 };
    const nodesInTier = this.props.nodes.filter(n => n.tier === node.tier).length;
    const tierIndex = this.props.nodes.filter(n => n.tier === node.tier).indexOf(node);
    
    // Spread nodes vertically within each tier
    const yOffset = (tierIndex - (nodesInTier - 1) / 2) * NODE_SPACING;
    
    return {
      x: tierBase.x,
      y: tierBase.y + yOffset,
    };
  }

  drawTree() {
    const canvas = this.canvasRef.current;
    if (!canvas) return;
    
    const ctx = canvas.getContext('2d');
    const { nodes } = this.props;
    const { offsetX, offsetY, zoom } = this.state;
    
    // Check if nodes exist
    if (!nodes || !Array.isArray(nodes) || nodes.length === 0) {
      // Draw a message if no nodes
      ctx.font = '16px Arial';
      ctx.fillStyle = '#888';
      ctx.textAlign = 'center';
      ctx.fillText('No research nodes available', canvas.width / 2, canvas.height / 2);
      return;
    }
    
    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // Save context state
    ctx.save();
    
    // Apply transformations
    ctx.translate(offsetX, offsetY);
    ctx.scale(zoom, zoom);
    
    // Draw connections first (behind nodes)
    nodes.forEach((node, index) => {
      const nodePos = this.getNodePosition(node, index);
      
      // Draw lines to prerequisites
      if (node.prerequisites && node.prerequisites.length > 0) {
        node.prerequisites.forEach(prereqId => {
          const prereqNode = nodes.find(n => n.id === prereqId);
          if (prereqNode) {
            const prereqIndex = nodes.indexOf(prereqNode);
            const prereqPos = this.getNodePosition(prereqNode, prereqIndex);
            
            ctx.beginPath();
            ctx.moveTo(prereqPos.x + NODE_WIDTH, prereqPos.y + NODE_HEIGHT / 2);
            ctx.lineTo(nodePos.x, nodePos.y + NODE_HEIGHT / 2);
            ctx.strokeStyle = node.status === 'locked' ? '#666' : '#888';
            ctx.lineWidth = 2;
            ctx.stroke();
            
            // Draw arrow
            const angle = Math.atan2(
              nodePos.y - prereqPos.y,
              nodePos.x - (prereqPos.x + NODE_WIDTH)
            );
            const arrowLength = 10;
            ctx.beginPath();
            ctx.moveTo(nodePos.x, nodePos.y + NODE_HEIGHT / 2);
            ctx.lineTo(
              nodePos.x - arrowLength * Math.cos(angle - Math.PI / 6),
              nodePos.y + NODE_HEIGHT / 2 - arrowLength * Math.sin(angle - Math.PI / 6)
            );
            ctx.moveTo(nodePos.x, nodePos.y + NODE_HEIGHT / 2);
            ctx.lineTo(
              nodePos.x - arrowLength * Math.cos(angle + Math.PI / 6),
              nodePos.y + NODE_HEIGHT / 2 - arrowLength * Math.sin(angle + Math.PI / 6)
            );
            ctx.stroke();
          }
        });
      }
    });
    
    // Draw nodes
    nodes.forEach((node, index) => {
      const pos = this.getNodePosition(node, index);
      
      // Draw node background
      ctx.fillStyle = NODE_COLORS[node.status];
      ctx.fillRect(pos.x, pos.y, NODE_WIDTH, NODE_HEIGHT);
      
      // Draw node border
      ctx.strokeStyle = this.state.selectedNode === node.id ? '#FFD700' : '#000';
      ctx.lineWidth = this.state.selectedNode === node.id ? 3 : 1;
      ctx.strokeRect(pos.x, pos.y, NODE_WIDTH, NODE_HEIGHT);
      
      // Draw node text
      ctx.fillStyle = '#FFF';
      ctx.font = '12px Arial';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      
      // Split long names
      const words = node.name.split(' ');
      const lines = [];
      let currentLine = '';
      
      words.forEach(word => {
        const testLine = currentLine ? `${currentLine} ${word}` : word;
        if (ctx.measureText(testLine).width > NODE_WIDTH - 10) {
          if (currentLine) {
            lines.push(currentLine);
            currentLine = word;
          } else {
            lines.push(word);
          }
        } else {
          currentLine = testLine;
        }
      });
      if (currentLine) {
        lines.push(currentLine);
      }
      
      // Draw each line
      const lineHeight = 14;
      const startY = pos.y + NODE_HEIGHT / 2 - (lines.length - 1) * lineHeight / 2;
      lines.forEach((line, i) => {
        ctx.fillText(line, pos.x + NODE_WIDTH / 2, startY + i * lineHeight);
      });
      
      // Draw progress bar if there's progress
      const progress = node.progress || 0;
      if (progress > 0 && node.status !== 'completed') {
        const barWidth = NODE_WIDTH - 20;
        const barHeight = 4;
        const barX = pos.x + 10;
        const barY = pos.y + NODE_HEIGHT - 20;
        
        // Background
        ctx.fillStyle = '#333';
        ctx.fillRect(barX, barY, barWidth, barHeight);
        
        // Progress
        const fillWidth = (progress / node.cost) * barWidth;
        ctx.fillStyle = '#4CAF50';
        ctx.fillRect(barX, barY, fillWidth, barHeight);
      }
      
      // Draw cost/progress
      ctx.font = '10px Arial';
      ctx.fillStyle = '#FFD700';
      const progressText = progress > 0 ? `${progress}/${node.cost}` : `${node.cost} pts`;
      ctx.fillText(progressText, pos.x + NODE_WIDTH / 2, pos.y + NODE_HEIGHT - 10);
    });
    
    // Restore context state
    ctx.restore();
  }

  handleCanvasClick(e) {
    const rect = this.canvasRef.current.getBoundingClientRect();
    const x = (e.clientX - rect.left - this.state.offsetX) / this.state.zoom;
    const y = (e.clientY - rect.top - this.state.offsetY) / this.state.zoom;
    
    // Check if click is on a node
    const { nodes } = this.props;
    for (let i = 0; i < nodes.length; i++) {
      const node = nodes[i];
      const pos = this.getNodePosition(node, i);
      
      if (x >= pos.x && x <= pos.x + NODE_WIDTH &&
          y >= pos.y && y <= pos.y + NODE_HEIGHT) {
        this.setState({ selectedNode: node.id });
        if (this.props.onNodeSelect) {
          this.props.onNodeSelect(node);
        }
        return;
      }
    }
    
    // Clicked empty space
    this.setState({ selectedNode: null });
    if (this.props.onNodeSelect) {
      this.props.onNodeSelect(null);
    }
  }

  render() {
    return (
      <div
        style={{
          position: 'relative',
          width: '100%',
          height: '100%',
          overflow: 'hidden',
          cursor: this.state.isDragging ? 'grabbing' : 'grab',
        }}
        onMouseDown={this.handleMouseDown}
        onMouseMove={this.handleMouseMove}
        onMouseUp={this.handleMouseUp}
        onMouseLeave={this.handleMouseUp}
        onWheel={this.handleWheel}>
        <canvas
          ref={this.canvasRef}
          width={800}
          height={600}
          onClick={this.handleCanvasClick}
          style={{
            border: '1px solid #444',
            backgroundColor: '#1a1a1a',
          }}
        />
        <Box
          position="absolute"
          top="5px"
          right="5px"
          backgroundColor="rgba(0, 0, 0, 0.7)"
          p={1}>
          <Box color="white" fontSize="12px">
            Zoom: {Math.round(this.state.zoom * 100)}%
          </Box>
          <Box color="gray" fontSize="10px">
            Drag to pan, scroll to zoom
          </Box>
        </Box>
      </div>
    );
  }
}

export const RCEResearch = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    storedParts,
    selectedResearch,
    researchTree,
    partsList,
    researchProgress,
  } = data;

  const [selectedTab, setSelectedTab] = useLocalState(context, 'selectedTab', 'tree');
  const [selectedNode, setSelectedNode] = useLocalState(context, 'selectedNode', null);

  return (
    <Window width={1000} height={700} resizable>
      <Window.Content>
        <Stack fill>
          <Stack.Item width="70%">
            <Section fill title="Research Tree" buttons={
              selectedResearch ? (
                <Box inline mr={2} color="yellow">
                  Feeding Parts To: <b>{researchTree?.find(n => n.id === selectedResearch)?.name || 'None'}</b>
                </Box>
              ) : (
                <Box inline mr={2} color="gray">
                  Select a research to feed parts
                </Box>
              )
            }>
              <ResearchTree
                nodes={researchTree || []}
                onNodeSelect={(node) => setSelectedNode(node)}
              />
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Stack vertical fill>
              <Stack.Item grow>
                <Tabs fluid>
                  <Tabs.Tab
                    selected={selectedTab === 'tree'}
                    onClick={() => setSelectedTab('tree')}>
                    Node Details
                  </Tabs.Tab>
                  <Tabs.Tab
                    selected={selectedTab === 'parts'}
                    onClick={() => setSelectedTab('parts')}>
                    Body Parts ({storedParts})
                  </Tabs.Tab>
                  <Tabs.Tab
                    selected={selectedTab === 'progress'}
                    onClick={() => setSelectedTab('progress')}>
                    Research Progress
                  </Tabs.Tab>
                </Tabs>
                {selectedTab === 'tree' && (
                  <Section fill scrollable>
                    {selectedNode ? (
                      <Stack vertical fill>
                        <Stack.Item>
                          <Box fontSize="16px" bold color="label">
                            {selectedNode.name}
                          </Box>
                          <Box fontSize="12px" color="gray" mb={1}>
                            Tier {selectedNode.tier} • {selectedNode.cost} points
                          </Box>
                          <Box mb={2}>{selectedNode.desc}</Box>
                        </Stack.Item>
                        
                        {selectedNode.requiredTraits && selectedNode.requiredTraits.length > 0 && (
                          <Stack.Item>
                            <Box bold color="gold">Required Traits (need at least one):</Box>
                            {selectedNode.requiredTraits.map(trait => (
                              <Box key={trait} ml={1}>• {trait}</Box>
                            ))}
                          </Stack.Item>
                        )}
                        
                        {selectedNode.favoredTraits && Object.keys(selectedNode.favoredTraits).length > 0 && (
                          <Stack.Item>
                            <Box bold color="green">Favored Traits:</Box>
                            {Object.entries(selectedNode.favoredTraits).map(([trait, bonus]) => (
                              <Box key={trait} ml={1}>
                                • {trait}: +{Math.round(bonus * 100)}%
                              </Box>
                            ))}
                          </Stack.Item>
                        )}
                        
                        {selectedNode.negativeTraits && Object.keys(selectedNode.negativeTraits).length > 0 && (
                          <Stack.Item>
                            <Box bold color="red">Negative Traits:</Box>
                            {Object.entries(selectedNode.negativeTraits).map(([trait, penalty]) => (
                              <Box key={trait} ml={1}>
                                • {trait}: {Math.round(penalty * 100)}%
                              </Box>
                            ))}
                          </Stack.Item>
                        )}
                        
                        <Stack.Item>
                          {selectedNode.status === 'available' ? (
                            selectedResearch === selectedNode.id ? (
                              <Button
                                fluid
                                icon="times"
                                color="red"
                                content="Stop Feeding Parts Here"
                                onClick={() => act('deselectResearch')}
                              />
                            ) : (
                              <Button
                                fluid
                                icon="flask"
                                color="green"
                                content="Feed Parts To This Research"
                                onClick={() => act('selectResearch', { nodeId: selectedNode.id })}
                              />
                            )
                          ) : selectedNode.status === 'completed' ? (
                            <Box textAlign="center" color="green">
                              <b>COMPLETED</b>
                            </Box>
                          ) : selectedNode.status === 'locked' ? (
                            <Box textAlign="center" color="gray">
                              Prerequisites not met
                            </Box>
                          ) : null}
                        </Stack.Item>
                      </Stack>
                    ) : (
                      <Box color="gray">
                        Select a research node to view details
                      </Box>
                    )}
                  </Section>
                )}
                
                {selectedTab === 'parts' && (
                  <Section fill scrollable>
                    <Stack vertical>
                      {!selectedResearch && (
                        <Stack.Item>
                          <Box p={1} backgroundColor="rgba(255, 0, 0, 0.1)" color="red">
                            <b>No research selected!</b> Select a research project from the tree to feed parts to it.
                          </Box>
                        </Stack.Item>
                      )}
                      <Stack.Item>
                        <Button
                          fluid
                          icon="cog"
                          content="Process Next Part"
                          disabled={!storedParts || !selectedResearch}
                          onClick={() => act('processPart')}
                        />
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          fluid
                          icon="cogs"
                          content="Process All Parts"
                          disabled={!storedParts || !selectedResearch}
                          onClick={() => act('processAll')}
                        />
                      </Stack.Item>
                      {partsList && partsList.map((part, index) => (
                        <Stack.Item key={index}>
                          <Box
                            p={1}
                            backgroundColor="rgba(255, 255, 255, 0.05)"
                            mb={1}>
                            <Box bold>{part.name}</Box>
                            <Box fontSize="11px" color="gray">
                              From: {part.source}
                            </Box>
                            <Box fontSize="11px">
                              Base Value: {part.baseValue} pts
                            </Box>
                            <Box fontSize="10px">
                              Traits: {part.traits.join(', ')}
                            </Box>
                          </Box>
                        </Stack.Item>
                      ))}
                    </Stack>
                  </Section>
                )}
                
                {selectedTab === 'progress' && (
                  <Section fill>
                    {currentResearch ? (
                      <Stack vertical fill>
                        <Stack.Item>
                          <Box fontSize="16px" bold>
                            {currentResearch.name}
                          </Box>
                        </Stack.Item>
                        <Stack.Item>
                          <ProgressBar
                            value={currentResearch.progress}
                            maxValue={currentResearch.cost}>
                            {currentResearch.progress} / {currentResearch.cost} points
                          </ProgressBar>
                        </Stack.Item>
                        <Stack.Item>
                          <Button
                            fluid
                            icon="times"
                            color="red"
                            content="Cancel Research"
                            onClick={() => act('cancelResearch')}
                          />
                        </Stack.Item>
                      </Stack>
                    ) : (
                      <Box color="gray">
                        No research in progress
                      </Box>
                    )}
                  </Section>
                )}
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
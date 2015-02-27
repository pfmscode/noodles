var IconRandom = React.createClass({
  render: function() {
    var size = this.props.size ? this.props.size : 24;

    return (
      <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} viewBox="0 0 24 24" className={this.props.classes}>
        <path d="M7 2v11h3v9l7-12h-4l4-8z"/>
      </svg>
    )
  }
});
